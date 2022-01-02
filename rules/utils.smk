rule concat_paired_reads:
    input: 
        R1 = READDIR + "/{sample}_1" + EXT,
        R2 = READDIR + "/{sample}_2" + EXT
    output: 
        config["resultDir"] + "/concat_reads/{sample}_concat.fq" + EXT 
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
        cat {input.R1} {input.R1} > {output}
        """
