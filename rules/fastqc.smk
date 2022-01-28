rule fastqc_pe:
    input:
        read    = READDIR + "/{sample}_{mate}" + EXT
    output:
        html    = RESULTDIR + "/01-QualityControl/fastqcPre/{sample}_{mate}.html",
        zip     = TEMPDIR + "/qc/fastqc_pre/{sample}_{mate}_fastqc.zip"
    params: "--quiet"
    log:
        "log/fastqc/{sample}_{mate}.log"
    threads: 
        1
    message:
        "fastqc_pre({wildcards.sample}_{wildcards.mate})"
    wrapper:
        "v0.86.0/bio/fastqc"


rule fastqc_se:
    input:
        read    = READDIR + "/{sample}" + EXT
    output:
        html    = RESULTDIR + "/01-QualityControl/fastqc_se/{sample}.html",
        zip     = TEMPDIR + "/qc/fastqc_se/{sample}_fastqc.zip"
    params: "--quiet"
    log:
        "log/fastqc/{sample}.log"
    threads: 
        1
    message:
        "fastqc_se({wildcards.sample})"
    wrapper:
        "v0.86.0/bio/fastqc"