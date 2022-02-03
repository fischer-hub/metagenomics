def get_concat_input(wildcards):
    if MERGER == "pear":
        return  [   RESULTDIR + "/pear/{wildcards.sample}.assembled.fastq".format(wildcards=wildcards),
                    RESULTDIR + "/pear/{wildcards.sample}.unassembled.forward.fastq".format(wildcards=wildcards),
                    RESULTDIR + "/pear/{wildcards.sample}.unassembled.reverse.fastq".format(wildcards=wildcards),
                    RESULTDIR + "/pear/{wildcards.sample}.discarded.fastq".format(wildcards=wildcards) ]
    elif MERGER == "bbmerge":
        return [    RESULTDIR + "/01-QualityControl/merged/{wildcards.sample}_merged_fastq.gz".format(wildcards=wildcards),
                    RESULTDIR + "/01-QualityControl/merged/{wildcards.sample}_unmerged_fastq.gz".format(wildcards=wildcards)  ]
    elif MERGER == "none" and TRIM == "true":
        return [    RESULTDIR + "/01-QualityControl/trimmed_pe/{sample}_1.fastq.gz",
                    RESULTDIR + "/01-QualityControl/trimmed_pe/{sample}_2.fastq.gz",
                    TEMPDIR + "/TRIMMOMATIC/untrimmed_pe/{sample}_1.unpaired.fastq.gz",
                    TEMPDIR + "/TRIMMOMATIC/untrimmed_pe/{sample}_2.unpaired.fastq.gz"  ]
    else:
        return [    READDIR + "/{wildcards.sample}_1".format(wildcards=wildcards) + EXT,
                    READDIR + "/{wildcards.sample}_2".format(wildcards=wildcards) + EXT   ]


rule concat_paired_reads:
    input: 
        unpack(get_concat_input)
    output: 
        RESULTDIR + "/concat_reads/{sample}_concat.fq.gz"
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
