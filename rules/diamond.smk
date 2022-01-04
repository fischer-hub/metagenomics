rule diamond_makedb:
    output:
        config["cacheDir"] + "/databases/diamond/nr.dmnd"
    params:
        prot_nr_db = "https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz"
    threads:
        16
    shell:
        """
        wget {params.prot_nr_db}
        diamond makedb -p {threads} --in nr.gz --db {output}
        """

rule diamond_blastx:
    input:
        reads   = config["resultDir"] + "/concat_reads/{sample}_concat.fq" + EXT
    output: 
        config["resultDir"] + "/diamond/{sample}.daa"
    params:
        db      = config["cacheDir"] + "/databases/diamond/nr.dmnd"
    shell:
        """
        diamond blastx -q {input.reads} -d {params.db} --fast -o {output} -f 6
        """
