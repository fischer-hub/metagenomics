rule diamond_makedb:
    output:
        os.path.join(CACHEDIR, "databases", "diamond", "nr.dmnd")
    params:
        prot_ref_db_src = "https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz",
        prot_ref_db_dir = os.path.join(CACHEDIR, "databases", "protein_reference")
    conda:
        os.path.join("..", "envs", "diamond.yaml")
    resources:  
        time        = RES["diamond_makedb"]["time"],
        mem_mb      = RES["diamond_makedb"]["mem"] * 1024,
        partition   = RES["diamond_makedb"]["partition"]
    threads:
        RES["diamond_makedb"]["cpu"]
    message:
        "diamond_makedb\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    log:
        wget    = os.path.join(RESULTDIR, "00-Log", "diamond", "wget.log"),
        makedb  = os.path.join(RESULTDIR, "00-Log", "diamond", "makedb.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "diamond", "makedb.benchmark.txt")
    shell:
        """
        wget --directory-prefix={params.prot_ref_db_dir} {params.prot_ref_db_src}  2> {log.wget}
        diamond makedb -p {threads} --in {params.prot_ref_db_dir}/nr.gz --db {output}  2> {log.makedb}
        """

rule diamond_blastx:
    input:
        db      = os.path.join(CACHEDIR, "databases", "diamond", "nr.dmnd"),
        reads   = get_diamond_reads
    output: 
        os.path.join(TEMPDIR, "diamond", "{sample}.daa")
    params:
        num_index_chunks = IDX_CHUNKS,
        block_size = BLOCK_SIZE,
        id_th = ID_TH,
        top_range = TOP_RANGE
    conda:
        os.path.join("..", "envs", "diamond.yaml")
    resources:
        time        = RES["diamond_blastx"]["time"],
        mem_mb      = lambda wildcards,attempt: ((BLOCK_SIZE * 7 + BLOCK_SIZE * attempt) * RES["diamond_blastx"]["mem"] * 1024),
        partition   = RES["diamond_blastx"]["partition"]
    threads:
        RES["diamond_blastx"]["cpu"]
    message:
        "diamond_blastx({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    log:
        os.path.join(RESULTDIR, "00-Log", "diamond", "{sample}_blastx.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "diamond", "{sample}_blastx.benchmark.txt")
    shell:
        """
        diamond blastx --top 1 --id 80 -p {threads} -q {input.reads} -d {input.db} -o {output} -f 100 -b {params.block_size} -c {params.num_index_chunks} 2> {log}
        """
