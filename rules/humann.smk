def get_humann_reads(wildcards):
    if REFERENCE != "":
        return os.path.join(RESULTDIR, "02-Decontamination", "{wildcards.sample}_unmapped.fastq.gz".format(wildcards=wildcards))
    else:
        return os.path.join(TEMPDIR, "concat_reads", "{wildcards.sample}_concat.fq.gz".format(wildcards=wildcards))

rule humann_databases:
    log:
        c = os.path.join(RESULTDIR, "00-Log", "humann", "humann_databases_ChocoPhlAn.log"),
        u = os.path.join(RESULTDIR, "00-Log", "humann", "humann_databases_UniRef.log")
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
        nucDB   = os.path.join(CACHEDIR, "databases", "humann", "nuc"),
        protDB  = os.path.join(CACHEDIR, "databases", "humann", "prot"),
        reads   = get_humann_reads
    output: 
        genefamilies    = os.path.join(TEMPDIR, "humann", "raw", "{sample}_genefamilies.tsv"),
        pathways        = os.path.join(TEMPDIR, "humann", "raw", "{sample}_pathabundance.tsv"),
        pathCov         = os.path.join(TEMPDIR, "humann", "raw", "{sample}_pathcoverage.tsv")
    log:
        os.path.join(RESULTDIR, "00-Log", "humann", "compute", "{sample}_humann.log")
    conda:
        os.path.join("..", "envs", "humann.yaml")
    threads:
        24
    resources:
        time=1200,
        partition="big"
    params:
        outdir      = os.path.join(TEMPDIR, "humann", "raw", "{sample}_genefamilies.tsv").rsplit('/',1)[0],
        read_len    = 45
    message:
        "humann_compute({wildcards.sample})"
    shell: 
        "humann --metaphlan-options=\"--read_min_len {params.read_len}\" --threads {threads} -i {input.reads} -o {params.outdir} --nucleotide-database {input.nucDB}/*/ --protein-database {input.protDB}/*/ --output-basename {wildcards.sample} --verbose 2> {log} > /dev/null"


rule humann_join:
    input: 
        genefamilies    = expand(os.path.join(TEMPDIR, "humann", "raw", "{sample}_genefamilies.tsv"), sample = SAMPLE),
        pathabundance   = expand(os.path.join(TEMPDIR, "humann", "raw", "{sample}_pathcoverage.tsv"), sample = SAMPLE),
        pathCov         = expand(os.path.join(TEMPDIR, "humann", "raw", "{sample}_pathabundance.tsv"), sample = SAMPLE)
    output:
        genefamilies    = os.path.join(TEMPDIR, "humann", "genefamilies_combined.tsv"),
        pathways        = os.path.join(TEMPDIR, "humann", "pathabundance_combined.tsv"),
        pathCov         = os.path.join(TEMPDIR, "humann", "pathcoverage_combined.tsv")
    log:
        os.path.join(RESULTDIR, "00-Log", "humann", "join", "humann.log")
    conda:
        os.path.join("..", "envs", "humann.yaml")
    threads:
        8
    resources:
        time=240
    params:
        tabledir    = os.path.join(TEMPDIR, "humann", "raw", "{sample}_genefamilies.tsv").rsplit('/',1)[0]
    message:
        "humann_join"
    shell:
        """
        humann_join_tables --input {params.tabledir} --output {output.genefamilies} --file_name genefamilies 2> {log} > /dev/null
        humann_join_tables --input {params.tabledir} --output {output.pathCov} --file_name pathcoverage 2>> {log} > /dev/null
        humann_join_tables --input {params.tabledir} --output {output.pathways} --file_name pathabundance 2>> {log} > /dev/null
        """


rule humann_normalize:
    input: 
        genefamilies    = os.path.join(TEMPDIR, "humann", f"genefamilies_combined.tsv"),
        pathabundance   = os.path.join(TEMPDIR, "humann", f"pathabundance_combined.tsv"),
        pathCov         = os.path.join(TEMPDIR, "humann", "pathcoverage_combined.tsv")
    output:
        genefamilies    = os.path.join(RESULTDIR, "03-CountData", "humann", f"genefamilies_{UNITS}_combined.tsv"),
        pathabundance   = os.path.join(RESULTDIR, "03-CountData", "humann", f"pathabundance_{UNITS}_combined.tsv"),
        pathCov         = os.path.join(RESULTDIR, "03-CountData", "humann", "pathcoverage_normalized_combined.tsv")
    log:
        os.path.join(RESULTDIR, "00-Log", "humann", "humann_norm.log")
    conda:
        os.path.join("..", "envs", "humann.yaml")
    threads:
        8
    resources:
        time=240
    params:
        outdir = os.path.join(RESULTDIR, "03-CountData", "humann"),
        units = UNITS
    message:
        "humann_norm"
    shell:
        """
        humann_renorm_table --input {input.genefamilies} --output {output.genefamilies} --units {params.units} 2> {log}
        humann_renorm_table --input {input.pathabundance} --output {output.pathabundance} --units {params.units} 2>> {log}
        mv {input.pathCov} {output.pathCov} 2>> {log}
        """