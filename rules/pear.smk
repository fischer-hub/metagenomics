rule pear:
    input:
        unpack(merge_input)
    output:
        assembled_pairs = os.path.join(RESULTDIR, "01-QualityControl", "merged", "{sample}.assembled.fastq"),
        unassembled_fwd = os.path.join(RESULTDIR, "01-QualityControl", "merged", "{sample}.unassembled.forward.fastq"),
        unassembled_rev = os.path.join(RESULTDIR, "01-QualityControl", "merged", "{sample}.unassembled.reverse.fastq"),
        discarded_reads = os.path.join(RESULTDIR, "01-QualityControl", "merged", "{sample}.discarded.fastq")
    params:
        resultDir = lambda w, output: output[0].split("01-QualityControl")[0]
    log:
        os.path.join(RESULTDIR, "00-Log", "pear", "{sample}_pear.log")
    conda:
        os.path.join("..", "envs", "pear.yaml")
    message:
        "pear({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    resources:
        time        = RES["pear"]["time"],
        mem_mb      = RES["pear"]["mem"] * 1024,
        partition   = RES["pear"]["partition"]
    threads:
        RES["pear"]["cpu"]
    shell:
        """
        mkdir -p {params.resultDir}/pear/
        pear -b 64 --threads {threads} --forward-fastq {input.R1} --reverse-fastq {input.R2} --output {params.resultDir}/pear/{wildcards.sample} > {log}
        #mv {wildcards.sample}.assembled.fastq {output.assembled_pairs} >> {log}
        #mv {wildcards.sample}.unassembled.forward.fastq {output.unassembled_fwd} >> {log}
        #mv {wildcards.sample}.unassembled.reverse.fastq {output.unassembled_rev} >> {log}
        #mv {wildcards.sample}.discarded.fastq {output.discarded_reads} >> {log}
        """