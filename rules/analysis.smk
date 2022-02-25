def dga_counts(wildcards):

    humann  = [ os.path.join(RESULTDIR, "03-CountData", "humann", "genefamilies_" + UNITS  + "_combined.tsv")   ]
    megan   = [ os.path.join(RESULTDIR, "03-CountData", "megan", "megan_combined.csv")    ]

    if wildcards.tool == "humann": return humann
    else: return megan

rule differential_gene_analysis:
    input: 
        counts      = dga_counts,
        metadata    = config["metadata_csv"],
        comparisons = config["contrast_csv"]
    output:
        flag        = os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}","dga_{tool}.done")
    log:
        os.path.join(RESULTDIR, "00-Log", "dga", "dga_{tool}.log")
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
        result_dir  = lambda w, output: output[0].split("04-DifferentialGeneAbundance")[0],
        tool        = lambda w, output: os.path.splitext(os.path.split(output[0])[1])[0].split("_")[1]
    message:
        "differential_gene_analysis({wildcards.tool})"
    shell:
        """
        [ ! -d {params.work_dir} ] && mkdir  -p {params.work_dir}
        Rscript -e "rmarkdown::render('scripts/differential_abundance_{params.tool}.Rmd', output_file = '../{params.result_dir}04-DifferentialGeneAbundance/{params.tool}/dga_{params.tool}.html',\
                                                        params=list(\
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
                                                        tool = '{params.tool}',
                                                        result_dir = '{params.result_dir}'))" >& {log}
        """