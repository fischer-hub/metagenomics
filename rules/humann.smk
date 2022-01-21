def get_humann_reads(wildcards):
    if config["bowtie2_reference"] != "":
        return config["resultDir"] + "/bowtie2/{wildcards.sample}_unmapped.fastq.gz".format(wildcards=wildcards)
    else:
        return config["resultDir"] + "/concat_reads/{wildcards.sample}_concat.fq".format(wildcards=wildcards) + EXT

rule humann_databases:
    log:
        c = "log/humann/humann_databases_ChocoPhlAn.log",
        u = "log/humann/humann_databases_UniRef.log"
    output:
        nucDB   = directory(config["cacheDir"] + "/databases/humann/nuc"),
        protDB  = directory(config["cacheDir"] + "/databases/humann/prot")
    params:
        u_build     = config["protDB_build"],
        c_build     = config["nucDB_build"],
        installDir  = config["cacheDir"] + "/databases/humann"
    conda:
        WD + "envs/humann.yaml"
    threads:
        2
    message:
        "humann_database"
    shell:
        """
        mkdir -p {params.installDir}
        humann_databases --download chocophlan {params.c_build} {params.installDir}/nuc 2> {log.c}
        humann_databases --download uniref {params.u_build} {params.installDir}/prot 2> {log.u}       
        """

rule humann_compute:
    input: 
        nucDB   = config["cacheDir"] + "/databases/humann/nuc",
        protDB  = config["cacheDir"] + "/databases/humann/prot",
        reads   = get_humann_reads
    output: 
        genefamilies    = config["resultDir"] + "/humann/raw/{sample}_genefamilies.tsv",
        pathways        = config["resultDir"] + "/humann/raw/{sample}_pathabundance.tsv",
        pathCov         = config["resultDir"] + "/humann/raw/{sample}_pathcoverage.tsv"
    log:
        "log/humann/compute/{sample}_humann.log"
    conda:
        WD + "envs/humann.yaml"
    threads:
        24
    resources:
        runtime=960
    params:
        outdir = (config["resultDir"] + "/humann/raw/{sample}_genefamilies.tsv").rsplit('/',1)[0]
    message:
        "humann_compute({wildcards.sample})"
    shell: 
        "humann --threads {threads} -i {input.reads} -o {params.outdir} --nucleotide-database {input.nucDB}/*/ --protein-database {input.protDB}/*/ --output-basename {wildcards.sample} --verbose 2> {log}"

rule humann_normalize:
    input: 
        genefamilies    = config["resultDir"] + "/humann/raw/{sample}_genefamilies.tsv",
        pathabundance   = config["resultDir"] + "/humann/raw/{sample}_pathabundance.tsv",
        pathCov         = config["resultDir"] + "/humann/raw/{sample}_pathcoverage.tsv"
    output:
        genefamilies    = config["resultDir"] + "/humann/norm/{sample}_genefamilies_"  + config["humann_count_units"] + ".tsv",
        pathabundance   = config["resultDir"] + "/humann/norm/{sample}_pathabundance_" + config["humann_count_units"] + ".tsv",
        pathCov         = config["resultDir"] + "/humann/norm/{sample}_pathcoverage.tsv"
    log:
        "log/humann/normalize/{sample}_humann.log"
    conda:
        WD + "envs/humann.yaml"
    threads:
        8
    resources:
        runtime=240
    params:
        outdir = (config["resultDir"] + "/humann/norm/{sample}_genefamilies.tsv").rsplit('/',1)[0],
        units = config["humann_count_units"]
    message:
        "humann_norm({wildcards.sample})"
    shell:
        """
        humann_renorm_table --input {input.genefamilies} --output {output.genefamilies} --units {params.units}
        humann_renorm_table --input {input.pathabundance} --output {output.pathabundance} --units {params.units}
        mv {input.pathCov} {params.outdir}/
        """

rule humann_join:
    input: 
        genefamilies    = expand(config["resultDir"] + "/humann/norm/{sample}_genefamilies_"  + config["humann_count_units"] + ".tsv", sample = SAMPLE),
        pathabundance   = expand(config["resultDir"] + "/humann/norm/{sample}_pathabundance_" + config["humann_count_units"] + ".tsv", sample = SAMPLE),
        pathCov         = expand(config["resultDir"] + "/humann/norm/{sample}_pathcoverage.tsv", sample = SAMPLE)
    output:
        genefamilies    = config["resultDir"] + "/humann/genefamilies_" + config["humann_count_units"]  + "_combined.tsv",
        pathways        = config["resultDir"] + "/humann/pathabundance_" + config["humann_count_units"] + "_combined.tsv",
        pathCov         = config["resultDir"] + "/humann/pathcoverage_combined.tsv"
    log:
        "log/humann/join/humann.log"
    conda:
        WD + "envs/humann.yaml"
    threads:
        8
    resources:
        runtime=240
    params:
        tabledir = (config["resultDir"] + "/humann/norm/{sample}_genefamilies.tsv").rsplit('/',1)[0]
    message:
        "humann_join"
    shell:
        """
        humann_join_tables --input {params.tabledir} --output {output.genefamilies} --file_name genefamilies_relab
        humann_join_tables --input {params.tabledir} --output {output.pathCov} --file_name pathcoverage
        humann_join_tables --input {params.tabledir} --output {output.pathways} --file_name pathabundance_relab
        """