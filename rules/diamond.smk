def get_blast_mem(wildcards, attempt):
    return ((config["dmnd_block_size"] * 7 + config["dmnd_block_size"] * attempt) * 1024)

def get_diamond_reads(wildcards):
    if config["bowtie2_reference"] != "":
        return config["resultDir"] + "/bowtie2/{wildcards.sample}_unmapped.fastq.gz"
    else:
        return config["resultDir"] + "/concat_reads/{wildcards.sample}_concat.fq" + EXT

rule diamond_makedb:
    output:
        config["cacheDir"] + "/databases/diamond/nr.dmnd"
    params:
        prot_ref_db_src = "https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz",
        prot_ref_db_dir = config["cacheDir"] + "/databases/protein_reference/"
    threads:
        16
    conda:
        WD + "envs/diamond.yaml"
    resources:
        runtime=1200
    message:
        "diamond_makedb"
    log:
        wget = "log/diamond/wget.log",
        makedb = "log/diamond/makedb.log"
    shell:
        """
        wget --directory-prefix={params.prot_ref_db_dir} {params.prot_ref_db_src}  2> {log.wget}
        diamond makedb -p {threads} --in {params.prot_ref_db_dir}nr.gz --db {output}  2> {log.makedb}
        """

rule diamond_blastx:
    input:
        db      = config["cacheDir"] + "/databases/diamond/nr.dmnd",
        reads   = get_diamond_reads
    output: 
        config["resultDir"] + "/diamond/{sample}.daa"
    params:
        num_index_chunks = config["dmnd_num_index_chunks"],
        block_size = config["dmnd_block_size"]
    conda:
        WD + "envs/diamond.yaml"
    resources:
        runtime=1200,
        mem_mb=get_blast_mem
    threads:
        16
    message:
        "diamond_blastx({wildcards.sample})"
    log:
        "log/diamond/{sample}_blastx.log",
    shell:
        """
        diamond blastx -p {threads} -q {input.reads} -d {input.db} -o {output} -f 100 -b {params.block_size} -c {params.num_index_chunks} 2> {log}
        """
