
rule trimmomatic_pe:
    input:
        r1 = READDIR + "/{sample}_1" + EXT,
        r2 = READDIR + "/{sample}_2" + EXT
    output:
        r1 = RESULTDIR + "/01-QualityControl/trimmed/{sample}_1.fastq.gz",
        r2 = RESULTDIR + "/01-QualityControl/trimmed/{sample}_2.fastq.gz",
        # reads where trimming entirely removed the mate
        # this should not happen to us since we only trim adapters meaning one read would have to consist of only adapter sequence
        # EDIT: this seems to actually happen 
        r1_unpaired = TEMPDIR + "/TRIMMOMATIC/untrimmed/{sample}_1.unpaired.fastq.gz",
        r2_unpaired = TEMPDIR + "/TRIMMOMATIC/untrimmed/{sample}_2.unpaired.fastq.gz"
    log:
        "log/trimmomatic_pe/{sample}.log"
    params:
        # list of trimmers (see manual)
        trimmer=["ILLUMINACLIP:" + config["trimmomatic"]["adapters"] + ":" + config["trimmomatic"]["max_mismatch"] + ":" + config["trimmomatic"]["pThreshold"] + ":" + config["trimmomatic"]["sThreshold"]],
        #trimmer=["TRAILING:3"],
        # optional parameters
        extra="",
        compression_level="-9"
    threads:
        32
    resources:
        mem_mb=1024
    message:
        "trimmomatic_pe({wildcards.sample})"
    wrapper:
        "v0.86.0/bio/trimmomatic/pe"

rule trimmomatic_se:
    input:
        "reads/{sample}.fastq.gz"  # input and output can be uncompressed or compressed
    output:
        "trimmed/{sample}.fastq.gz"
    log:
        "log/trimmomatic_se/{sample}.log"
    params:
        # list of trimmers (see manual)
        trimmer=["TRAILING:3"],
        # optional parameters
        extra="",
        # optional compression levels from -0 to -9 and -11
        compression_level="-9"
    threads:
        32
    resources:
        mem_mb=1024
    message:
        "trimmomatic_se({wildcards.sample})"
    wrapper:
        "v0.86.0/bio/trimmomatic/se"