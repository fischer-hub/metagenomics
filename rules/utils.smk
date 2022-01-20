def get_concat_input(wildcards):
    if config["merge_reads"] == "true":
        dd = {  "assembled_pairs": config["resultDir"] + "/pear/{wildcards.sample}.assembled.fastq".format(wildcards=wildcards),
                "unassembled_fwd": config["resultDir"] + "/pear/{wildcards.sample}.unassembled.forward.fastq".format(wildcards=wildcards),
                "unassembled_rev": config["resultDir"] + "/pear/{wildcards.sample}.unassembled.reverse.fastq".format(wildcards=wildcards),
                "discarded_reads": config["resultDir"] + "/pear/{wildcards.sample}.discarded.fastq".format(wildcards=wildcards) }
    else:
        dd = {  "R1": READDIR + "/{wildcards.sample}_1".format(wildcards=wildcards) + EXT,
                "R2": READDIR + "/{wildcards.sample}_2".format(wildcards=wildcards) + EXT }
    return dd


rule concat_paired_reads:
    input: 
        unpack(get_concat_input)
    output: 
        config["resultDir"] + "/concat_reads/{sample}_concat.fq"
    log:
        "log/concat_paired_reads/{sample}_concat.log"
    conda:
        WD + "envs/utils.yaml"
    threads:
        1
    message:
        "concat_paired_reads({wildcards.sample})"
    shell: 
        """
        cat {input} > {output}
        """
