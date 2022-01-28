rule megan_get_db:
    output:
        directory(config["cacheDir"] + "/databases/megan/")
    conda:
       WD + "envs/utils.yaml"
    resources:
        runtime=120
    message:
        "megan_get_db"
    log:
        wget = "log/megan/wget.log",
        gunzip = "log/megan/gunzip.log"
    shell:
        """
        wget --directory-prefix={output} https://software-ab.informatik.uni-tuebingen.de/download/megan6/megan-map-Jan2021.db.zip 2> {log.wget}
        unzip {output}/megan-map-Jan2021.db.zip -d {output} 2> {log.gunzip}
        """


rule daa_meganize:
    input: 
        megan_db_dir    = config["cacheDir"] + "/databases/megan",
        daa             = config["resultDir"] + "/diamond/{sample}.daa"
    output:
        meganized_daa   = config["resultDir"] + "/megan/meganized_daa/{sample}_meganized.daa"
    params:
        megan_db_dir    = config["cacheDir"] + "/databases/megan/"
    log:
        "log/megan/{sample}_daa_meganizer.log"
    conda:
        WD + "envs/megan.yaml"
    threads:
        16
    message:
        "daa_meganize({wildcards.sample})"
    resources:
        runtime=960
    shell:
        """
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
        meganized_daa   = config["resultDir"] + "/megan/meganized_daa/{sample}_meganized.daa"
    output:
        counts          = config["resultDir"] + "/megan/counts/{sample}.tsv"
    log:
        "log/megan/{sample}_daa2info.log"
    conda:
        WD + "envs/megan.yaml"
    params:
        outdir = config["resultDir"] + "/megan/counts"
    threads:
        1
    message:
        "daa_to_info({wildcards.sample})"
    shell:
        """
        mkdir -p {params.outdir} 2> {log}
        daa2info --in {input} -es {output} 2>> {log} #-es -> report all classifications: /DBNAME/DBID (no prefix)/COUNTS/, -c2c DB -> report one DB, --names replace ID with full ID and NAME
        awk '!/@/ && !/END/ && !/daa/{{printf ("%1s%2s\\t%3s\\n", $1, $2, $3)}}' {output} > temp.tsv 2>> {log} # merge db and id 
        mv temp.tsv {output} 2>> {log}
        """

rule join_megan_tsv:
    input:
        expand(config["resultDir"] + "/megan/counts/{sample}.tsv", sample = SAMPLE)
    output:
        combined = config["resultDir"] + "/megan/megan_combined.csv"
    message:
        "join_megan_tsv"
    run:
        frames = [ pd.read_csv(f, sep='\t', index_col=0, names=["gene_id", f]) for f in input ]
        result = frames[0].join(frames[1:])
        result.fillna(0, inplace=True)
        result = result.astype(int)
        result.to_csv(output.combined, header=(",".join(input)), na_rep='0')