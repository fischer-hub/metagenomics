def get_blast_mem(wildcards, attempt):
    return ((BLOCK_SIZE * 7 + BLOCK_SIZE * attempt) * 1024)

def get_diamond_reads(wildcards):
    if REFERENCE != "":
        return os.path.join(RESULTDIR, "bowtie2", "{wildcards.sample}_unmapped.fastq.gz".format(wildcards=wildcards))
    else:
        return os.path.join(RESULTDIR, "concat_reads", "{wildcards.sample}_concat.fq.gz".format(wildcards=wildcards))

rule diamond_makedb:
    output:
        os.path.join(CACHEDIR, "databases", "diamond", "nr.dmnd")
    params:
        prot_ref_db_src = "https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz",
        prot_ref_db_dir = os.path.join(CACHEDIR, "databases", "protein_reference")
    threads:
        16
    conda:
        os.path.join("..", "envs", "diamond.yaml")
    resources:
        time=1200
    message:
        "diamond_makedb"
    log:
        wget    = os.path.join(RESULTDIR, "log", "diamond", "wget.log"),
        makedb  = os.path.join(RESULTDIR, "log", "diamond", "makedb.log")
    shell:
        """
        wget --directory-prefix={params.prot_ref_db_dir} {params.prot_ref_db_src}  2> {log.wget}
        diamond makedb -p {threads} --in {params.prot_ref_db_dir}nr.gz --db {output}  2> {log.makedb}
        """

rule diamond_blastx:
    input:
        db      = os.path.join(CACHEDIR, "databases", "diamond", "nr.dmnd"),
        reads   = get_diamond_reads
    output: 
        os.path.join(RESULTDIR, "diamond", "{sample}.daa")
    params:
        num_index_chunks = IDX_CHUNKS,
        block_size = BLOCK_SIZE
    conda:
        os.path.join("..", "envs", "diamond.yaml")
    resources:
        time=2880,
        mem_mb=get_blast_mem,
        partition="big"
    threads:
        24
    message:
        "diamond_blastx({wildcards.sample})"
    log:
        os.path.join(RESULTDIR, "log", "diamond", "{sample}_blastx.log"),
    shell:
        """
        diamond blastx -p {threads} -q {input.reads} -d {input.db} -o {output} -f 100 -b {params.block_size} -c {params.num_index_chunks} 2> {log}
        """
