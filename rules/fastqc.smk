rule fastqc_pe:
    input:
        read    = os.path.join(READDIR, f"{{sample}}_{{mate}}{EXT}")
    output:
        html    = os.path.join(RESULTDIR, "01-QualityControl", "fastqcPre", "{sample}_{mate}.html"),
        zip     = os.path.join(TEMPDIR, "qc", "fastqc_pre", "{sample}_{mate}_fastqc.zip")
    params: "--quiet"
    log:
        os.path.join("log", "fastqc", "{sample}_{mate}.log")
    threads: 
        RES["fastqc"]["cpu"]
    message:
        "fastqc_pre({wildcards.sample}_{wildcards.mate})"
    wrapper:
        "v0.86.0/bio/fastqc"


rule fastqc_se:
    input:
        read    = os.path.join(READDIR, f"{{sample}}{EXT}")
    output:
        html    = os.path.join(RESULTDIR, "01-QualityControl", "fastqc_se", "{sample}.html"),
        zip     = os.path.join(TEMPDIR, "qc", "fastqc_se", "{sample}_fastqc.zip")
    params: "--quiet"
    log:
        os.path.join("log", "fastqc", "{sample}.log")
    threads: 
        RES["fastqc"]["cpu"]
    message:
        "fastqc_se({wildcards.sample})"
    wrapper:
        "v0.86.0/bio/fastqc"