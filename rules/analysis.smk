rule differential_gene_analysis:
    input: 
        counts      = dga_counts,
        metadata    = config["metadata_csv"],
        comparisons = config["contrast_csv"]
    output:
        flag             = os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}","dga_{tool}.done"),
        logFC_con        = os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Data", "logFC_per_contrast.tsv"),
        count_dist       = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "count_distribution.png"), caption="../assets/report/count_dist.rst", category="DGA-General", subcategory = "Histograms"),
        count_dist_log   = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "count_distribution_log.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "Histograms"),
        heat_gen         = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "heatmap_top_50_count_gen.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "Heatmaps"),
        heat_gen_log     = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "heatmap_top_50_count_log_gen.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "Heatmaps"),
        sample2sample    = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "sample_to_sample_dist_count.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "Heatmaps"),
        sample2sample_log= report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "sample_to_sample_dist_log_count.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "Heatmaps"),
        pca_gen          = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "pca_general.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "PCAs"),
        pca_log_gen      = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "pca_log_general.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "PCAs"),
        volcano_gen      = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "volcano_plot_general.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "Others"),
        ma_gen           = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "ma_plot_general.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "Others"),
        upset_con        = report(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Overview", "Plots", "upset_plot_per_contrast.png"), caption="../assets/report/test.rst", category="DGA-General", subcategory = "Others"),
        contrasts        = report(directory(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "{tool}", "Contrasts")), patterns=["{contrast1}/Plots/{name}.png"], caption="../assets/report/test.rst", category="DGA-{contrast1}", subcategory = "{contrast1}")
    log:
        os.path.join(RESULTDIR, "00-Log", "dga", "dga_{tool}.log")
    conda:
        os.path.join("..", "envs", "analysis.yaml")
    resources:
        time        = RES["dga_analysis"]["time"],
        mem_mb      = RES["dga_analysis"]["mem"] * 1024,
        partition   = RES["dga_analysis"]["partition"]
    threads:
        RES["dga_analysis"]["cpu"]
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
        "differential_gene_analysis({wildcards.tool})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    shell:
        """
        [ ! -d {params.work_dir} ] && mkdir  -p {params.work_dir}
        Rscript -e "rmarkdown::render('scripts/differential_abundance_{params.tool}.Rmd', output_file = '../{params.result_dir}04-DifferentialGeneAbundance/{params.tool}/dga_{params.tool}.html',\
                                                        params=list(\
                                                        counts = '{input.counts}',\
                                                        metadata = '{input.metadata}', \
                                                        show_code = 'TRUE', \
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

rule compare_results:
    input:
        counts_megan        = os.path.join(RESULTDIR, "03-CountData", "megan", "megan_combined.csv"),
        counts_humann       = os.path.join(RESULTDIR, "03-CountData", "humann", "genefamilies_cpm_combined_eggNOG.tsv"),
        logFC_con_megan     = os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "megan", "Overview", "Data", "logFC_per_contrast.tsv"),
        logFC_con_humann    = os.path.join(RESULTDIR, "03-CountData", "humann", "logFC_per_contrast_eggNOG.tsv")
    output:
        upset               = report(directory(os.path.join(RESULTDIR, "05-Summary", "ToolComparison")), patterns=["{name}.png"], caption="../assets/report/test.rst", category="Tool-Comparison"),
        common_csv          = os.path.join(RESULTDIR, "05-Summary", "ToolComparison", "common_feature_hits.csv")
    log:
        os.path.join(RESULTDIR, "00-Log", "dga", "compare_results.log")
    conda:
        os.path.join("..", "envs", "analysis.yaml")
    resources:
        time        = RES["compare_results"]["time"],
        mem_mb      = RES["compare_results"]["mem"] * 1024,
        partition   = RES["compare_results"]["partition"]
    threads:
        RES["compare_results"]["cpu"]
    params:
        result_dir = os.path.join("..", RESULTDIR, "05-Summary"),
        height      = HEIGHT,
        width       = WIDTH
    message:
        "compare_results\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    shell:
        """
        Rscript -e "rmarkdown::render('scripts/compare.Rmd', output_file = '{params.result_dir}/compare_results.html',\
                                                        params=list(\
                                                        counts_megan = '{input.counts_megan}',\
                                                        counts_humann = '{input.counts_humann}', \
                                                        logFC_con_humann = '{input.logFC_con_humann}', \
                                                        logFC_con_megan = '{input.logFC_con_megan}', \
                                                        result_dir = '{params.result_dir}',
                                                        plot_height = {params.height},
                                                        plot_width = {params.width}))" >& {log}
        """