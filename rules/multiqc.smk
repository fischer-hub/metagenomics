rule multiqc:
    input:
        get_reports
    output:
        os.path.join(RESULTDIR, "05-Summary", "multiqc.html")
    params:
        ""  # Optional: extra parameters for multiqc.
    log:
        os.path.join(RESULTDIR, "00-Log", "multiqc.log")
    message:
        "multiqc"
    wrapper:
        "v0.86.0/bio/multiqc"