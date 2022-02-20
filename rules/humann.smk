def get_humann_reads(wildcards):
    if REFERENCE != "":
        return os.path.join(RESULTDIR, "bowtie2", "{wildcards.sample}_unmapped.fastq.gz".format(wildcards=wildcards))
    else:
        return os.path.join(RESULTDIR, "concat_reads", "{wildcards.sample}_concat.fq.gz".format(wildcards=wildcards))

rule humann_databases:
    log:
        c = os.path.join("log", "humann", "humann_databases_ChocoPhlAn.log"),
        u = os.path.join("log", "humann", "humann_databases_UniRef.log")
    output:
        nucDB   = directory(os.path.join(CACHEDIR, "databases", "humann", "nuc")),
        protDB  = directory(os.path.join(CACHEDIR, "databases", "humann", "prot"))
    params:
        u_build     = config["protDB_build"],
        c_build     = config["nucDB_build"],
        installDir  = os.path.join(CACHEDIR, "databases", "humann")
    conda:
        os.path.join("..", "envs", "humann.yaml")
    resources:
        time = RES["humann_database"]["time"]
    threads:
        RES["humann_database"]["cpu"]
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
        nucDB   = os.path.join(CACHEDIR, "databases", "humann", "nuc"),
        protDB  = os.path.join(CACHEDIR, "databases", "humann", "prot"),
        reads   = get_humann_reads
    output: 
        genefamilies    = os.path.join(RESULTDIR, "humann", "raw", "{sample}_genefamilies.tsv"),
        pathways        = os.path.join(RESULTDIR, "humann", "raw", "{sample}_pathabundance.tsv"),
        pathCov         = os.path.join(RESULTDIR, "humann", "raw", "{sample}_pathcoverage.tsv")
    log:
        os.path.join("log", "humann", "compute", "{sample}_humann.log")
    conda:
        os.path.join("..", "envs", "humann.yaml")
    threads:
        RES["humann_compute"]["cpu"]
    resources:
        time = RES["humann_compute"]["time"],
        partition="big"
    params:
        outdir      = os.path.join(RESULTDIR, "humann", "raw", "{sample}_genefamilies.tsv").rsplit('/',1)[0],
        read_len    = 45
    message:
        "humann_compute({wildcards.sample})"
    shell: 
        "humann --metaphlan-options=\"--read_min_len {params.read_len}\" --threads {threads} -i {input.reads} -o {params.outdir} --nucleotide-database {input.nucDB}/*/ --protein-database {input.protDB}/*/ --output-basename {wildcards.sample} --verbose 2> {log} > /dev/null"


rule humann_join:
    input: 
        genefamilies    = expand(os.path.join(RESULTDIR, "humann", "raw", "{sample}_genefamilies.tsv"), sample = SAMPLE),
        pathabundance   = expand(os.path.join(RESULTDIR, "humann", "raw", "{sample}_pathcoverage.tsv"), sample = SAMPLE),
        pathCov         = expand(os.path.join(RESULTDIR, "humann", "raw", "{sample}_pathabundance.tsv"), sample = SAMPLE)
    output:
        genefamilies    = os.path.join(RESULTDIR, "humann", "genefamilies_combined.tsv"),
        pathways        = os.path.join(RESULTDIR, "humann", "pathabundance_combined.tsv"),
        pathCov         = os.path.join(RESULTDIR, "humann", "pathcoverage_combined.tsv")
    log:
        os.path.join("log", "humann", "join", "humann.log")
    conda:
        os.path.join("..", "envs", "humann.yaml")
    threads:
        RES["humann_join"]["cpu"]
    resources:
        time = RES["humann_join"]["time"]
    params:
        tabledir    = os.path.join(RESULTDIR, "humann", "raw", "{sample}_genefamilies.tsv").rsplit('/',1)[0]
    message:
        "humann_join"
    shell:
        """
        humann_join_tables --input {params.tabledir} --output {output.genefamilies} --file_name genefamilies 2> {log}
        humann_join_tables --input {params.tabledir} --output {output.pathCov} --file_name pathcoverage 2>> {log}
        humann_join_tables --input {params.tabledir} --output {output.pathways} --file_name pathabundance 2>> {log}
        """


rule humann_normalize:
    input: 
        genefamilies    = os.path.join(RESULTDIR, "humann", f"genefamilies_combined.tsv"),
        pathabundance   = os.path.join(RESULTDIR, "humann", f"pathabundance_combined.tsv"),
        pathCov         = os.path.join(RESULTDIR, "humann", "pathcoverage_combined.tsv")
    output:
        genefamilies    = os.path.join(RESULTDIR, "humann", f"genefamilies_{UNITS}_combined.tsv"),
        pathabundance   = os.path.join(RESULTDIR, "humann", f"pathabundance_{UNITS}_combined.tsv"),
        pathCov         = os.path.join(RESULTDIR, "humann", "pathcoverage_normalized_combined.tsv")
    log:
        os.path.join("log", "humann", "humann_norm.log")
    conda:
        os.path.join("..", "envs", "humann.yaml")
    threads:
        RES["humann_normalize"]["cpu"]
    resources:
        time = RES["humann_normalize"]["time"]
    params:
        outdir = os.path.join(RESULTDIR, "humann"),
        units = UNITS
    message:
        "humann_norm({wildcards.sample})"
    shell:
        """
        humann_renorm_table --input {input.genefamilies} --output {output.genefamilies} --units {params.units} 2> {log}
        humann_renorm_table --input {input.pathabundance} --output {output.pathabundance} --units {params.units} 2>> {log}
        mv {input.pathCov} {params.outdir}/ 2>> {log}
        """