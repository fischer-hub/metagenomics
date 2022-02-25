rule concat_paired_reads:
    input: 
        unpack(get_concat_input)
    output: 
        os.path.join(TEMPDIR, "concat_reads", "{sample}_concat.fq.gz")
    log:
        os.path.join(RESULTDIR, "00-Log", "concat_paired_reads", "{sample}_concat.log")
    conda:
        os.path.join("..", "envs", "utils.yaml")
    threads:
        1
    message:
        "concat_paired_reads({wildcards.sample})"
    shell: 
        """
        cat {input} > {output}
        """
