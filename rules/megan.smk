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
        gunzip {output}/megan-map-Jan2021.db.zip 2> {log.gunzip}
        """


rule daa_meganize:
    input: 
        megan_db_dir    = config["cacheDir"] + "/databases/megan",
        daa             = config["resultDir"] + "/diamond/{sample}.daa"
    output:
        flag            = touch("temp/megan/{sample}.done")
    params:
        megan_db_dir = config["cacheDir"] + "/databases/megan/"
    log:
        "log/megan/{sample}.log"
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
        daa-meganizer -i {input.daa} -mdb {input.megan_db_dir}/megan-map-Jan2021.db -t {threads} 2> {log}
        """ 