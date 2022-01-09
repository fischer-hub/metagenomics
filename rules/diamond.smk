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
    shell:
        """
        wget --directory-prefix={params.prot_ref_db_dir} {params.prot_ref_db_src}
        diamond makedb -p {threads} --in {params.prot_ref_db_dir}nr.gz --db {output}
        """

rule diamond_blastx:
    input:
        db      = config["cacheDir"] + "/databases/diamond/nr.dmnd",
        reads   = config["resultDir"] + "/concat_reads/{sample}_concat.fq" + EXT
    output: 
        config["resultDir"] + "/diamond/{sample}.daa"
    #params:
    conda:
        WD + "envs/diamond.yaml"
    resources:
        runtime=1200
    threads:
        16
    shell:
        """
        diamond blastx -p {threads} -q {input.reads} -d {input.db} -o {output} -f 6
        """
