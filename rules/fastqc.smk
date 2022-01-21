rule fastqcPre:
    input:
        read    = READDIR + "/{sample}_{mate}" + EXT
    output:
        html    = RESULTDIR + "/01-QualityControl/fastqcPre/{sample}_{mate}.html",
        zip     = TEMPDIR + "/qc/fastqc/{sample}_{mate}_fastqc.zip"
    params: "--quiet"
    log:
        "log/fastqc/{sample}_{mate}.log"
    threads: 
        1
    message:
        "fastqc_pre({wildcards.sample}_{wildcards.mate})"
    wrapper:
        "v0.86.0/bio/fastqc"

rule fastqcPost:
    input:
        "reads/{sample}.fastq"
    output:
        html="qc/fastqc/{sample}.html",
        zip="qc/fastqc/{sample}_fastqc.zip"
    params: "--quiet"
    log:
        "logs/fastqc/{sample}.log"
    threads: 
        1
    message:
        "fastqc_post({wildcards.sample})"
    wrapper:
        "v0.86.0/bio/fastqc"