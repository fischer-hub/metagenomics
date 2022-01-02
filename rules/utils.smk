# just concatenating everything
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

# merge paired reads to improve contiguity (carnelian merge script)
rule merge_pairs:
    input:
        R1 = READDIR + "/{sample}_1" + EXT,
        R2 = READDIR + "/{sample}_2" + EXT,
        seutil_flag = "temp/flags/sequtil.done",
        ldpc_flag = "temp/flags/ldpc.done",
        bio_flag = "temp/flags/Bio.done"
    log:
        "log/merge_pairs/{sample}_merge.log"
    threads:
        1
    message:
        "merge_pairs({wildcards.sample})"
    output:
        config["resultDir"] + "/merged_pairs/{sample}_merged.fq" + EXT
    shell: 
        "python bin/carnelian/util/merged_pairs.py -g {output} {input.R1} {input.R2}"