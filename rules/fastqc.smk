rule fastqc_pe_pre:
    input:
        read    = os.path.join(READDIR, f"{{sample}}_{{mate}}{EXT}")
    output:
        html    = os.path.join(RESULTDIR, "01-QualityControl", "fastqc_pe_pre", "{sample}_{mate}.html"),
        zip     = os.path.join(TEMPDIR, "qc", "fastqc_pe_pre", "{sample}_{mate}_fastqc.zip")
    params: "--quiet"
    log:
        os.path.join(RESULTDIR, "00-Log", "fastqc_pe_pre", "{sample}_{mate}.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "fastqc_pe_pre", "{sample}_{mate}.benchmark.txt")
    resources:
        time        = RES["fastqc"]["time"],
        mem_mb      = RES["fastqc"]["mem"] * 1024,
        partition   = RES["fastqc"]["partition"]
    threads:
        RES["fastqc"]["cpu"]
    message:
        "fastqc_pre({wildcards.sample}_{wildcards.mate})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    wrapper:
        "v0.86.0/bio/fastqc"


rule fastqc_se_pre:
    input:
        read    = os.path.join(READDIR, f"{{sample}}{EXT}")
    output:
        html    = os.path.join(RESULTDIR, "01-QualityControl", "fastqc_se_pre", "{sample}.html"),
        zip     = os.path.join(TEMPDIR, "qc", "fastqc_se_pre", "{sample}_fastqc.zip")
    params: "--quiet"
    log:
        os.path.join(RESULTDIR, "00-Log", "fastqc_se_pre", "{sample}.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "fastqc_se_pre", "{sample}.benchmark.txt")
    resources:
        time        = RES["fastqc"]["time"],
        mem_mb      = RES["fastqc"]["mem"] * 1024,
        partition   = RES["fastqc"]["partition"]
    threads:
        RES["fastqc"]["cpu"]
    message:
        "fastqc_pre({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    wrapper:
        "v0.86.0/bio/fastqc"


rule fastqc_pe_post:
    input:
        reads   = os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{sample}_{mate}.fastq.gz"),
    output:
        html    = os.path.join(RESULTDIR, "01-QualityControl", "fastqc_pe_post", "{sample}_{mate}.html"),
        zip     = os.path.join(TEMPDIR, "qc", "fastqc_pe_post", "{sample}_{mate}_fastqc.zip")
    params: "--quiet"
    log:
        os.path.join(RESULTDIR, "00-Log", "fastqc_pe_post", "{sample}_{mate}.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "fastqc_pe_post", "{sample}_{mate}.benchmark.txt")
    resources:
        time        = RES["fastqc"]["time"],
        mem_mb      = RES["fastqc"]["mem"] * 1024,
        partition   = RES["fastqc"]["partition"]
    threads:
        RES["fastqc"]["cpu"]
    message:
        "fastqc_post({wildcards.sample}_{wildcards.mate})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    wrapper:
        "v0.86.0/bio/fastqc"


rule fastqc_se_post:
    input:
        read    = os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{sample}.fastq.gz")
    output:
        html    = os.path.join(RESULTDIR, "01-QualityControl", "fastqc_se_post", "{sample}.html"),
        zip     = os.path.join(TEMPDIR, "qc", "fastqc_se_post", "{sample}_fastqc.zip")
    params: "--quiet"
    log:
        os.path.join(RESULTDIR, "00-Log", "fastqc_se_post", "{sample}.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "fastqc_se_post", "{sample}.benchmark.txt")
    resources:
        time        = RES["fastqc"]["time"],
        mem_mb      = RES["fastqc"]["mem"] * 1024,
        partition   = RES["fastqc"]["partition"]
    threads:
        RES["fastqc"]["cpu"]
    message:
        "fastqc_post({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    wrapper:
        "v0.86.0/bio/fastqc"