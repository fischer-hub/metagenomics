rule multiqc:
    input:
        get_reports
    output:
        os.path.join(RESULTDIR, "05-Summary", "multiqc.html")
    params:
        ""  # Optional: extra parameters for multiqc.
    log:
        os.path.join(RESULTDIR, "00-Log", "multiqc.log")
    benchmark:
        os.path.join(RESULTDIR, "06-Benchmark", "multiqc.log")
    message:
        "multiqc\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    resources:
        time        = RES["multiqc"]["time"],
        mem_mb      = RES["multiqc"]["mem"] * 1024,
        partition   = RES["multiqc"]["partition"]
    threads:
        RES["multiqc"]["cpu"]
    wrapper:
        "v0.86.0/bio/multiqc"