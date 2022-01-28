def get_reports(wildcards):

    reports = []
    if MERGER == "bbmerge":
        reports.extend(expand(TEMPDIR   + "/bbmerge/{sample}_ihist.txt", sample = SAMPLE))

    if config["bowtie2_reference"] != "":
        reports.extend(expand("log/bowtie2/bowtie2_map_{sample}.log", sample = SAMPLE))

    if FASTQC and param_mode == "paired":
        reports.extend(expand(TEMPDIR + "/qc/fastqc_pre/{sample}_{mate}_fastqc.zip", sample = SAMPLE, mate = ["1", "2"]))
    if FASTQC:
        reports.extend(expand(TEMPDIR + "/qc/fastqc_se/{sample}_fastqc.zip", sample = SAMPLE))

    return reports


rule multiqc:
    input:
        get_reports
    output:
        RESULTDIR + "/Summary/multiqc.html"
    params:
        ""  # Optional: extra parameters for multiqc.
    log:
        "log/multiqc.log"
    message:
        "multiqc"
    wrapper:
        "v0.86.0/bio/multiqc"