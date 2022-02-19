def get_humann_reads(wildcards):
    if REFERENCE != "":
        return RESULTDIR + "/bowtie2/{wildcards.sample}_unmapped.fastq.gz".format(wildcards=wildcards)
    else:
        return RESULTDIR + "/concat_reads/{wildcards.sample}_concat.fq.gz".format(wildcards=wildcards)

rule humann_databases:
    log:
        c = "log/humann/humann_databases_ChocoPhlAn.log",
        u = "log/humann/humann_databases_UniRef.log"
    output:
        nucDB   = directory(CACHEDIR + "/databases/humann/nuc"),
        protDB  = directory(CACHEDIR + "/databases/humann/prot")
    params:
        u_build     = config["protDB_build"],
        c_build     = config["nucDB_build"],
        installDir  = CACHEDIR + "/databases/humann"
    conda:
        WD + "envs/humann.yaml"
    resources:
        time=240
    threads:
        2
    message:
        "humann_database"
    shell:
        """
        mkdir -p {params.installDir}
        humann_databases --download chocophlan {params.c_build} {params.installDir}/nuc 2> {log.c} > /dev/null
        humann_databases --download uniref {params.u_build} {params.installDir}/prot 2> {log.u} > /dev/null     
        """

rule humann_compute:
    input: 
        nucDB   = CACHEDIR + "/databases/humann/nuc",
        protDB  = CACHEDIR + "/databases/humann/prot",
        reads   = get_humann_reads
    output: 
        genefamilies    = RESULTDIR + "/humann/raw/{sample}_genefamilies.tsv",
        pathways        = RESULTDIR + "/humann/raw/{sample}_pathabundance.tsv",
        pathCov         = RESULTDIR + "/humann/raw/{sample}_pathcoverage.tsv"
    log:
        "log/humann/compute/{sample}_humann.log"
    conda:
        WD + "envs/humann.yaml"
    threads:
        24
    resources:
        time=1200,
        partition="big"
    params:
        outdir      = (RESULTDIR + "/humann/raw/{sample}_genefamilies.tsv").rsplit('/',1)[0],
        read_len    = 45
    message:
        "humann_compute({wildcards.sample})"
    shell: 
        "humann --metaphlan-options=\"--read_min_len {params.read_len}\" --threads {threads} -i {input.reads} -o {params.outdir} --nucleotide-database {input.nucDB}/*/ --protein-database {input.protDB}/*/ --output-basename {wildcards.sample} --verbose 2> {log}"

rule humann_normalize:
    input: 
        genefamilies    = RESULTDIR + "/humann/raw/{sample}_genefamilies.tsv",
        pathabundance   = RESULTDIR + "/humann/raw/{sample}_pathabundance.tsv",
        pathCov         = RESULTDIR + "/humann/raw/{sample}_pathcoverage.tsv"
    output:
        genefamilies    = RESULTDIR + "/humann/norm/{sample}_genefamilies_"  + UNITS + ".tsv",
        pathabundance   = RESULTDIR + "/humann/norm/{sample}_pathabundance_" + UNITS + ".tsv",
        pathCov         = RESULTDIR + "/humann/norm/{sample}_pathcoverage.tsv"
    log:
        "log/humann/normalize/{sample}_humann.log"
    conda:
        WD + "envs/humann.yaml"
    threads:
        8
    resources:
        time=240
    params:
        outdir = (RESULTDIR + "/humann/norm/{sample}_genefamilies.tsv").rsplit('/',1)[0],
        units = UNITS
    message:
        "humann_norm({wildcards.sample})"
    shell:
        """
        humann_renorm_table --input {input.genefamilies} --output {output.genefamilies} --units {params.units} 2> {log}
        humann_renorm_table --input {input.pathabundance} --output {output.pathabundance} --units {params.units} 2>> {log}
        mv {input.pathCov} {params.outdir}/ 2>> {log}
        """

rule humann_join:
    input: 
        genefamilies    = expand(RESULTDIR + "/humann/norm/{sample}_genefamilies_"  + UNITS + ".tsv", sample = SAMPLE),
        pathabundance   = expand(RESULTDIR + "/humann/norm/{sample}_pathabundance_" + UNITS + ".tsv", sample = SAMPLE),
        pathCov         = expand(RESULTDIR + "/humann/norm/{sample}_pathcoverage.tsv", sample = SAMPLE)
    output:
        genefamilies    = RESULTDIR + "/humann/genefamilies_" + UNITS  + "_combined.tsv",
        pathways        = RESULTDIR + "/humann/pathabundance_" + UNITS + "_combined.tsv",
        pathCov         = RESULTDIR + "/humann/pathcoverage_combined.tsv"
    log:
        "log/humann/join/humann.log"
    conda:
        WD + "envs/humann.yaml"
    threads:
        8
    resources:
        time=240
    params:
        tabledir    = (RESULTDIR + "/humann/norm/{sample}_genefamilies.tsv").rsplit('/',1)[0],
        units       = UNITS
    message:
        "humann_join"
    shell:
        """
        humann_join_tables --input {params.tabledir} --output {output.genefamilies} --file_name genefamilies_{params.units} 2> {log}
        humann_join_tables --input {params.tabledir} --output {output.pathCov} --file_name pathcoverage 2>> {log}
        humann_join_tables --input {params.tabledir} --output {output.pathways} --file_name pathabundance_{params.units} 2>> {log}
        """