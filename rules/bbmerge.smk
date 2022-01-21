def bbmerge_input(wildcards):
    if config["qc"] == "true":
        return  {   R1 = RESULTDIR + "/01-QualityControl/trimmed/{sample}_1.fastq.gz",
                    R1 = RESULTDIR + "/01-QualityControl/trimmed/{sample}_2.fastq.gz"    }
    else:
        return  {   R1 = READDIR + "/{sample}_1" + EXT,
                    R1 = READDIR + "/{sample}_2" + EXT   }

rule bbmerge:
    input:
        unpack(bbmerge_input)
    output:
        merged      = RESULTDIR + "/01-QualityControl/merged/{sample}_merged_fastq.gz",
        unmerged    = RESULTDIR + "/01-QualityControl/merged/{sample}_unmerged_fastq.gz",
        inserthist  = TEMPDIR   + "/bbmerge/{sample}_ihist.txt"
    params:
        ref_dir  = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1]
    log:
        "log/bbmerge/{sample}_merge.log"
    conda:
        WD + "envs/bbmerge.yaml"
    threads:
        16
    message:
        "bbmerge({wildcards.sample})"
    resources:
        runtime=480
    shell:
        """
        bbmerge.sh in1={input.R1} in2={input.R1} out={output.merged} outu={output.unmerged} ihist={output.inserthist} 2> {log}
        """