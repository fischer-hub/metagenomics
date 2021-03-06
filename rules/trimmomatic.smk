rule trimmomatic_pe:
    input:
        r1 = os.path.join(READDIR, f"{{sample}}_1{EXT}"),
        r2 = os.path.join(READDIR, f"{{sample}}_2{EXT}")
    output:
        r1 = os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{sample}_1.fastq.gz"),
        r2 = os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{sample}_2.fastq.gz"),
        # reads where trimming entirely removed the mate
        # this should not happen to us since we only trim adapters meaning one read would have to consist of only adapter sequence
        # EDIT: this seems to actually happen 
        r1_unpaired = os.path.join(TEMPDIR, "TRIMMOMATIC", "untrimmed_pe", "{sample}_1.unpaired.fastq.gz"),
        r2_unpaired = os.path.join(TEMPDIR, "TRIMMOMATIC", "untrimmed_pe", "{sample}_2.unpaired.fastq.gz")
    log:
        os.path.join(RESULTDIR, "00-Log", "trimmomatic_pe", "{sample}.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "trimmomatic_pe", "{sample}.benchmark.txt")    
    params:
        # list of trimmers (see manual)
        trimmer=[f"ILLUMINACLIP:{ADPT_PE}:{MAX_MISMATCH}:{P_TH}:{S_TH}:{MIN_ADPT_LEN}:True"],
        #trimmer=["TRAILING:3"],
        # optional parameters
        extra="",
        compression_level="-9"
    resources:
        time        = RES["trimmomatic"]["time"],
        mem_mb      = RES["trimmomatic"]["mem"] * 1024,
        partition   = RES["trimmomatic"]["partition"]
    threads:
        RES["trimmomatic"]["cpu"]
    message:
        "trimmomatic_pe({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    wrapper:
        "v0.86.0/bio/trimmomatic/pe"


rule trimmomatic_se:
    input:
        os.path.join(READDIR, "{sample}", EXT)
    output:
        os.path.join(RESULTDIR, "01-QualityControl", "trimmed_se", "{sample}.fastq.gz")
    log:
        os.path.join(RESULTDIR, "00-Log", "trimmomatic_se", "{sample}.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "trimmomatic_se", "{sample}.benchmark.txt")
    params:
        # list of trimmers (see manual)
        # :2:True LEADING:3 TRAILING:3 MINLEN:36
        trimmer=[f"ILLUMINACLIP:{ADPT_SE}:{MAX_MISMATCH}:{P_TH}:{S_TH}:{MIN_ADPT_LEN}:True"],
        # optional parameters
        extra="",
        # optional compression levels from -0 to -9 and -11
        compression_level="-9"
    resources:
        time        = RES["trimmomatic"]["time"],
        mem_mb      = RES["trimmomatic"]["mem"] * 1024,
        partition   = RES["trimmomatic"]["partition"]
    threads:
        RES["trimmomatic"]["cpu"]
    message:
        "trimmomatic_se({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    wrapper:
        "v0.86.0/bio/trimmomatic/se"