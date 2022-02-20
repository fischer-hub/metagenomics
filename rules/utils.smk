def get_concat_input(wildcards):
    if MERGER == "pear":
        return  [   os.path.join(RESULTDIR, "pear", "{wildcards.sample}.assembled.fastq".format(wildcards=wildcards)),
                    os.path.join(RESULTDIR, "pear", "{wildcards.sample}.unassembled.forward.fastq".format(wildcards=wildcards)),
                    os.path.join(RESULTDIR, "pear", "{wildcards.sample}.unassembled.reverse.fastq".format(wildcards=wildcards)),
                    os.path.join(RESULTDIR, "pear", "{wildcards.sample}.discarded.fastq".format(wildcards=wildcards)) ]
    elif MERGER == "bbmerge":
        return [    os.path.join(RESULTDIR, "01-QualityControl", "merged", "{wildcards.sample}_merged_fastq.gz".format(wildcards=wildcards)),
                    os.path.join(RESULTDIR, "01-QualityControl", "merged", "{wildcards.sample}_unmerged_fastq.gz".format(wildcards=wildcards))  ]
    elif MERGER == "none" and TRIM == "true":
        return [    os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{sample}_1.fastq.gz"),
                    os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{sample}_2.fastq.gz"),
                    os.path.join(TEMPDIR, "TRIMMOMATIC", "untrimmed_pe", "{sample}_1.unpaired.fastq.gz"),
                    os.path.join(TEMPDIR, "TRIMMOMATIC", "untrimmed_pe", "{sample}_2.unpaired.fastq.gz")  ]
    else:
        return [    os.path.join(READDIR, "{wildcards.sample}_1".format(wildcards=wildcards), EXT),
                    os.path.join(READDIR, "{wildcards.sample}_2".format(wildcards=wildcards), EXT)   ]


rule concat_paired_reads:
    input: 
        unpack(get_concat_input)
    output: 
        os.path.join(RESULTDIR, "concat_reads", "{sample}_concat.fq.gz")
    log:
        os.path.join("log", "concat_paired_reads", "{sample}_concat.log")
    conda:
        os.path.join("..", "envs", "utils.yaml")
    threads:
        RES["concat_paired_reads"]["cpu"]
    message:
        "concat_paired_reads({wildcards.sample})"
    shell: 
        """
        cat {input} > {output}
        """
