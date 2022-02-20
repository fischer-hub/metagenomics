def dga_counts(wildcards):

    humann  = [ os.path.join(RESULTDIR, "humann", "genefamilies_" + UNITS  + "_combined.tsv")    ]
    megan   = [ os.path.join(RESULTDIR, "megan", "megan_combined.csv")  ]

    if "humann" in CORETOOLS and not "megan" in CORETOOLS: return humann
    elif "megan" in CORETOOLS and not "humann" in CORETOOLS: return megan
    else: return humann + megan

rule differential_gene_analysis:
    input: 
        counts      = dga_counts,
        metadata    = config["metadata_csv"],
        comparisons = config["contrast_csv"]
    output:
        flag        = os.path.join(TEMPDIR, "dga_{sample}.done")
    log:
        os.path.join("log", "dga", "dga_{sample}.log")
    conda:
        os.path.join("..", "envs", "analysis.yaml")
    threads:
        RES["dga_analysis"]["cpu"]
    resources:
        time = RES["dga_analysis"]["time"]
    params:
        tmp_dir     = TEMPDIR,
        formula     = FORMULA,
        height      = HEIGHT,
        width       = WIDTH,
        fc_th       = FC_TH,
        ab_th       = AB_TH,
        pr_th       = PR_TH,
        sig_th      = SIG_TH
    message:
        "differential_gene_analysis()"
    shell:
        """
        Rscript -e "rmarkdown::render('differential_abundance_humann.Rmd', params=list(\
                                                        counts = '{input.counts}',\
                                                        metadata = '{input.metadata}', \
                                                        show_code = FALSE, \
                                                        comparisons = '{input.comparisons}, \
                                                        formula = '{params.formula}', \
                                                        cpus = {threads},\
                                                        abundance_threshold = {params.ab_th}, \
                                                        prevalence_threshold = {params.pr_th}, \
                                                        alpha = {params.sig_th}, \
                                                        fc_threshold = {params.fc_th}, \
                                                        work_dir = '{params.tmp_dir}', \
                                                        plot_height = {params.height}, \
                                                        plot_width = {params.width})) 2> {log}"
        """ 

#rule dga_megan:
#    input: 
#    output: 
#    run: 