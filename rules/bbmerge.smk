def merge_input(wildcards):
    if TRIM == "true":
        return  {   "R1" : RESULTDIR + "/01-QualityControl/trimmed_pe/{wildcards.sample}_1.fastq.gz".format(wildcards=wildcards),
                    "R2" : RESULTDIR + "/01-QualityControl/trimmed_pe/{wildcards.sample}_2.fastq.gz".format(wildcards=wildcards)    }
    else:
        return  {   "R1" : READDIR + "/{wildcards.sample}_1".format(wildcards=wildcards) + EXT,
                    "R2" : READDIR + "/{wildcards.sample}_2".format(wildcards=wildcards) + EXT   }

rule bbmerge:
    input:
        unpack(merge_input)
    output:
        merged      = RESULTDIR + "/01-QualityControl/merged/{sample}_merged_fastq.gz",
        unmerged    = RESULTDIR + "/01-QualityControl/merged/{sample}_unmerged_fastq.gz",
        inserthist  = TEMPDIR   + "/bbmerge/{sample}_ihist.txt"
    log:
        "log/bbmerge/{sample}_merge.log"
    conda:
        WD + "envs/bbmerge.yaml"
    threads:
        16
    message:
        "bbmerge({wildcards.sample})"
    resources:
        runtime=480,
        mem_mb=10240
    shell: # check other params!! (ram, threads etc)
        """
        bbmerge.sh t={threads} ziplevel=5 default -Xmx10240m in1={input.R1} in2={input.R2} out={output.merged} outu={output.unmerged} ihist={output.inserthist} 2> {log}
        """