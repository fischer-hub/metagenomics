rule concat_paired_reads:
    input: 
        unpack(get_concat_input)
    output: 
        os.path.join(TEMPDIR, "concat_reads", "{sample}_concat.fq.gz")
    log:
        os.path.join(RESULTDIR, "00-Log", "concat_paired_reads", "{sample}_concat.log")
    conda:
        os.path.join("..", "envs", "utils.yaml")
    resources:
        time        = RES["concat_paired_reads"]["time"],
        mem_mb      = RES["concat_paired_reads"]["mem"] * 1024,
        partition   = RES["concat_paired_reads"]["partition"]
    threads:
        RES["concat_paired_reads"]["cpu"]
    message:
        "concat_paired_reads({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    shell: 
        """
        cat {input} > {output}
        """
