def get_reports(wildcards):
    reports = ["/bbmerge/{wildcards.sample}_ihist.txt"]
    if config["bowtie2_reference"] != "":
        reports.append("log/bowtie2/bowtie2_map_{wildcards.sample}.log")
    if config["qc"] == "true":
        reports.append(TEMPDIR + "/qc/fastqc_pre/{wildcards.sample}_{mate}_fastqc.zip")
    return reports

rule multiqc:
    input:
        get_reports
    output:
        RESULTDIR + "/Summary/multiqc.html"
    params:
        ""  # Optional: extra parameters for multiqc.
    log:
        "logs/multiqc.log"
    wrapper:
        "v0.86.0/bio/multiqc"