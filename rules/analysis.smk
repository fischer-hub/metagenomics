def dga_counts(wildcards):

    humann  = [ os.path.join(RESULTDIR, "03-CountData", "humann", "genefamilies_" + UNITS  + "_combined.tsv")   ]
    megan   = [ os.path.join(RESULTDIR, "03-CountData", "megan", "megan_combined.csv")    ]

    if "humann" in CORETOOLS and not "megan" in CORETOOLS: return humann
    elif "megan" in CORETOOLS and not "humann" in CORETOOLS: return megan
    else: return humann + megan

rule differential_gene_analysis:
    input: 
        counts      = dga_counts,
        metadata    = config["metadata_csv"],
        comparisons = config["contrast_csv"]
    output:
        flag        = os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}","dga_{tool}.done")
    log:
        os.path.join(RESULTDIR, "log", "dga", "dga_{tool}.log")
    conda:
        os.path.join("..", "envs", "analysis.yaml")
    threads:
        8
    resources:
        time=240
    params:
        work_dir    = WORK_DIR,
        formula     = FORMULA,
        height      = HEIGHT,
        width       = WIDTH,
        fc_th       = FC_TH,
        ab_th       = AB_TH,
        pr_th       = PR_TH,
        sig_th      = SIG_TH,
        result_dir  = RESULTDIR
    message:
        "differential_gene_analysis({wildcards.tool})"
    shell:
        """
        [ ! -d {params.work_dir} ] && mkdir  -p {params.work_dir}
        Rscript -e "rmarkdown::render('scripts/differential_abundance_{wildcards.tool}.Rmd', params=list(\
                                                        counts = '{input.counts}',\
                                                        metadata = '{input.metadata}', \
                                                        show_code = 'FALSE', \
                                                        comparisons = '{input.comparisons}', \
                                                        formula = '{params.formula}', \
                                                        cpus = {threads},\
                                                        abundance_threshold = {params.ab_th}, \
                                                        prevalence_threshold = {params.pr_th}, \
                                                        alpha = {params.sig_th}, \
                                                        fc_threshold = {params.fc_th}, \
                                                        work_dir = '{params.work_dir}', \
                                                        plot_height = {params.height}, \
                                                        plot_width = {params.width},
                                                        tool = '{wildcards.tool}',
                                                        result_dir = '{params.result_dir}'))" >& {log}
        """