def merge_input(wildcards):
    if TRIM == "true":
        return  {   "R1" : os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{wildcards.sample}_1.fastq.gz".format(wildcards=wildcards)),
                    "R2" : os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{wildcards.sample}_2.fastq.gz".format(wildcards=wildcards))    }
    else:
        return  {   "R1" : os.path.join(READDIR, "{wildcards.sample}_1".format(wildcards=wildcards), EXT),
                    "R2" : os.path.join(READDIR, "{wildcards.sample}_2".format(wildcards=wildcards), EXT)   }

rule bbmerge:
    input:
        unpack(merge_input)
    output:
        merged      = os.path.join(RESULTDIR, "01-QualityControl", "merged", "{sample}_merged_fastq.gz"),
        unmerged    = os.path.join(RESULTDIR, "01-QualityControl", "merged", "{sample}_unmerged_fastq.gz"),
        inserthist  = os.path.join(TEMPDIR,   "bbmerge", "{sample}_ihist.txt")
    log:
        os.path.join(RESULTDIR, "log", "bbmerge", "{sample}_merge.log")
    conda:
        os.path.join("..", "envs", "bbmerge.yaml")
    threads:
        16
    message:
        "bbmerge({wildcards.sample})"
    resources:
        time=480,
        mem_mb=10240
    shell:
        """
        bbmerge.sh t={threads} ziplevel=5 default -Xmx10240m in1={input.R1} in2={input.R2} out={output.merged} outu={output.unmerged} ihist={output.inserthist} 2> {log}
        """