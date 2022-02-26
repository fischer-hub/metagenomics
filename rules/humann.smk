rule humann_databases:
    log:
        c = os.path.join(RESULTDIR, "00-Log", "humann", "humann_databases_ChocoPhlAn.log"),
        u = os.path.join(RESULTDIR, "00-Log", "humann", "humann_databases_UniRef.log"),
        t = os.path.join(RESULTDIR, "00-Log", "humann", "humann_test.log")
    output:
        nucDB   = directory(os.path.join(CACHEDIR, "databases", "humann", "nuc")),
        protDB  = directory(os.path.join(CACHEDIR, "databases", "humann", "prot"))
    params:
        u_build     = config["protDB_build"],
        c_build     = config["nucDB_build"],
        installDir  = lambda w, output: os.path.split(output[0])[0], #os.path.join(CACHEDIR, "databases", "humann")
    conda:
        os.path.join("..", "envs", "humann.yaml")
    resources:
        time        = RES["humann_database"]["time"],
        mem_mb      = RES["humann_database"]["mem"] * 1024,
        partition   = RES["humann_database"]["partition"]
    threads:
        RES["humann_database"]["cpu"]
    message:
        "humann_database\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    shell:
        """
        mkdir -p {params.installDir}
        humann_databases --download chocophlan {params.c_build} {params.installDir}/nuc 2> {log.c} > /dev/null
        humann_databases --download uniref {params.u_build} {params.installDir}/prot 2> {log.u} > /dev/null
        humann_test --run-functional-tests-tools --run-functional-tests-end-to-end > {log.t}
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
    resources:
        time        = RES["humann_compute"]["time"],
        mem_mb      = RES["humann_compute"]["mem"] * 1024,
        partition   = RES["humann_compute"]["partition"]
    threads:
        RES["humann_compute"]["cpu"]
    params:
        outdir      = lambda w, output: os.path.split(output[0])[0], #os.path.join(TEMPDIR, "humann", "raw", "{sample}_genefamilies.tsv").rsplit('/',1)[0],
        read_len    = 45
    message:
        "humann_compute({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
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
    resources:
        time        = RES["humann_join"]["time"],
        mem_mb      = RES["humann_join"]["mem"] * 1024,
        partition   = RES["humann_join"]["partition"]
    threads:
        RES["humann_join"]["cpu"]
    params:
        tabledir    = os.path.join(TEMPDIR, "humann", "raw", "{sample}_genefamilies.tsv").rsplit('/',1)[0]
    message:
        "humann_join\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
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
    resources:
        time        = RES["humann_normalize"]["time"],
        mem_mb      = RES["humann_normalize"]["mem"] * 1024,
        partition   = RES["humann_normalize"]["partition"]
    threads:
        RES["humann_normalize"]["cpu"]
    params:
        outdir = lambda w, output: os.path.split(output[0])[0], #os.path.join(RESULTDIR, "03-CountData", "humann"),
        units = UNITS
    message:
        "humann_norm\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    shell:
        """
        humann_renorm_table --input {input.genefamilies} --output {output.genefamilies} --units {params.units} 2> {log}
        humann_renorm_table --input {input.pathabundance} --output {output.pathabundance} --units {params.units} 2>> {log}
        mv {input.pathCov} {output.pathCov} 2>> {log}
        """