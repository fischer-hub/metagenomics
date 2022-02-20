def get_reports(wildcards):

    reports = []
    if MERGER == "bbmerge":
        reports.extend(expand(os.path.join(TEMPDIR, "bbmerge", "{sample}_ihist.txt"), sample = SAMPLE))

    if REFERENCE != "":
        reports.extend(expand(os.path.join("log", "bowtie2", "bowtie2_map_{sample}.log"), sample = SAMPLE))

    if FASTQC and MODE == "paired":
        reports.extend(expand(os.path.join(TEMPDIR, "qc", "fastqc_pre", "{sample}_{mate}_fastqc.zip"), sample = SAMPLE, mate = ["1", "2"]))
    if FASTQC and MODE == "single":
        reports.extend(expand(os.path.join(TEMPDIR, "qc", "fastqc_se", "{sample}_fastqc.zip"), sample = SAMPLE))

    return reports


rule multiqc:
    input:
        get_reports
    output:
        os.path.join(RESULTDIR, "Summary", "multiqc.html")
    params:
        ""  # Optional: extra parameters for multiqc.
    log:
        os.path.join("log", "multiqc.log")
    message:
        "multiqc"
    threads:
        RES["multiqc"]["cpu"]
    wrapper:
        "v0.86.0/bio/multiqc"