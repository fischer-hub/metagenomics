rule megan_get_db:
    output:
        directory(os.path.join(CACHEDIR, "databases", "megan"))
    conda:
       os.path.join("..", "envs", "utils.yaml")
    resources:
        time        = RES["megan_get_db"]["time"],
        mem_mb      = RES["megan_get_db"]["mem"] * 1024,
        partition   = RES["megan_get_db"]["partition"]
    threads:
        RES["megan_get_db"]["cpu"]
    message:
        "megan_get_db\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    log:
        wget = os.path.join(RESULTDIR, "00-Log", "megan", "wget.log"),
        gunzip = os.path.join(RESULTDIR, "00-Log", "megan", "gunzip.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "megan", "megan_get_db.benchmark.txt")
    shell:
        """
        wget --directory-prefix={output} https://software-ab.informatik.uni-tuebingen.de/download/megan6/megan-map-Jan2021.db.zip 2> {log.wget} > /dev/null
        unzip {output}/megan-map-Jan2021.db.zip -d {output} 2> {log.gunzip} > /dev/null
        """


rule daa_meganize:
    input: 
        megan_db_dir    = os.path.join(CACHEDIR, "databases", "megan"),
        daa             = os.path.join(TEMPDIR, "diamond", "{sample}.daa")
    output:
        meganized_daa   = os.path.join(TEMPDIR, "megan", "meganized_daa", "{sample}_meganized.daa")
    log:
        os.path.join(RESULTDIR, "00-Log", "megan", "{sample}_daa_meganizer.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "megan", "{sample}_daa_meganizer.benchmark.txt")
    conda:
        os.path.join("..", "envs", "megan.yaml")
    message:
        "daa_meganize({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    resources:
        time        = RES["daa_meganize"]["time"],
        mem_mb      = RES["daa_meganize"]["mem"] * 1024,
        partition   = RES["daa_meganize"]["partition"]
    threads:
        RES["daa_meganize"]["cpu"]
    shell:
        """
        # set memory limit to 32 GB for MEGAN if not set already
        if ! tail -n 1 ${{CONDA_PREFIX}}/opt/megan-6.21.7/MEGAN.vmoptions | grep -q Xmx32000M; then
            head -n -1 ${{CONDA_PREFIX}}/opt/megan-6.21.7/MEGAN.vmoptions > temp.txt
            mv temp.txt ${{CONDA_PREFIX}}/opt/megan-6.21.7/MEGAN.vmoptions
            echo "-Xmx32000M" >> ${{CONDA_PREFIX}}/opt/megan-6.21.7/MEGAN.vmoptions
        fi

        # meganize .daa file
        daa-meganizer -i {input.daa} -mdb {input.megan_db_dir}/megan-map-Jan2021.db -t {threads} 2> {log}
        cp {input.daa} {output.meganized_daa} 2>> {log}
        """

rule daa_to_info:
    input: 
        meganized_daa   = os.path.join(TEMPDIR, "megan", "meganized_daa", "{sample}_meganized.daa")
    output:
        counts          = os.path.join(TEMPDIR, "megan", "counts", "{sample}.tsv")
    log:
        os.path.join(RESULTDIR, "00-Log", "megan", "{sample}_daa2info.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "megan", "{sample}_daa2info.benchmark.txt")
    conda:
        os.path.join("..", "envs", "megan.yaml")
    resources:
        time        = RES["daa_to_info"]["time"],
        mem_mb      = RES["daa_to_info"]["mem"] * 1024,
        partition   = RES["daa_to_info"]["partition"]
    threads:
        RES["daa_to_info"]["cpu"]
    message:
        "daa_to_info({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    shell:
        """
        daa2info --in {input} --names -c2c EGGNOG >> {output} 2>> {log}
        """

rule join_megan_tsv:
    input:
        expand(os.path.join(TEMPDIR, "megan", "counts", "{sample}.tsv"), sample = SAMPLE)
    output:
        combined = os.path.join(RESULTDIR, "03-CountData", "megan", "megan_combined.csv")
    message:
        "join_megan_tsv\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    log:
        os.path.join(RESULTDIR, "00-Log", "megan", "join_megan_tsv.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "megan", "join_megan_tsv.benchmark.txt")
    resources:
        time        = RES["join_megan_tsv"]["time"],
        mem_mb      = RES["join_megan_tsv"]["mem"] * 1024,
        partition   = RES["join_megan_tsv"]["partition"]
    threads:
        RES["join_megan_tsv"]["cpu"]
    run:
        frames = [ pd.read_csv(f, sep='\t', index_col=0, names=["gene_id", f]) for f in input ]
        result = frames[0].join(frames[1:])
        result.fillna(0, inplace=True)
        result = result.astype(int)
        result.to_csv(output.combined, header=(",".join(input)), na_rep='0')