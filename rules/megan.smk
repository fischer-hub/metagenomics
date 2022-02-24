rule megan_get_db:
    output:
        directory(os.path.join(CACHEDIR, "databases", "megan"))
    conda:
       os.path.join("..", "envs", "utils.yaml")
    resources:
        time=120
    message:
        "megan_get_db"
    log:
        wget = os.path.join(RESULTDIR, "00-Log", "megan", "wget.log"),
        gunzip = os.path.join(RESULTDIR, "00-Log", "megan", "gunzip.log")
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
    params:
        megan_db_dir    = os.path.join(CACHEDIR, "databases", "megan")
    log:
        os.path.join(RESULTDIR, "00-Log", "megan", "{sample}_daa_meganizer.log")
    conda:
        os.path.join("..", "envs", "megan.yaml")
    threads:
        16
    message:
        "daa_meganize({wildcards.sample})"
    resources:
        time=1200,
        partition="big"
    shell:
        """
        # this will not work if --conda-prefix is set to something else then ./.snakemake !!!
        # set memory limit to 32 GB for MEGAN if not set already
        if ( $(tail -f -n 1 /Users/shubhamsinha/Desktop/new_test.log | grep '-Xmx32000M') ); then
            head -n -1 $(find  .snakemake/conda/ -name 'MEGAN.vmoptions') > temp.txt
            mv temp.txt $(find  .snakemake/conda/ -name 'MEGAN.vmoptions')
            echo "-Xmx32000M" >> $(find  .snakemake/conda/ -name 'MEGAN.vmoptions')
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
    conda:
        os.path.join("..", "envs", "megan.yaml")
    threads:
        1
    message:
        "daa_to_info({wildcards.sample})"
    shell:
        """
        daa2info --in {input} --names -c2c EGGNOG >> {output} 2>> {log} 
        #for DB in EC EGGNOG INTERPRO2GO SEED; do
        #    daa2info --in {input} --names -c2c $DB >> {output} 2>> {log} 
        #done
        """

rule join_megan_tsv:
    input:
        expand(os.path.join(TEMPDIR, "megan", "counts", "{sample}.tsv"), sample = SAMPLE)
    output:
        combined = os.path.join(RESULTDIR, "03-CountData", "megan", "megan_combined.csv")
    message:
        "join_megan_tsv"
    run:
        frames = [ pd.read_csv(f, sep='\t', index_col=0, names=["gene_id", f]) for f in input ]
        result = frames[0].join(frames[1:])
        result.fillna(0, inplace=True)
        result = result.astype(int)
        result.to_csv(output.combined, header=(",".join(input)), na_rep='0')