rule dga_humann:
    input: 
        counts      = RESULTDIR + "/humann/genefamilies_" + UNITS  + "_combined.tsv"
        metadata    = config["metadata_csv"]
        comparisons = config["comparisons_csv"]
    output:
        flag        = config["work_dir"] + "/dga_humann.done"
    log:
        "log/dga/dga_humann.log"
    conda:
        "../envs/analysis.yaml"
    threads:
        8
    resources:
        time=240
    params:
        work_dir    = #project dir,
        formula     = config["formula"],
        height      = config["plot_height"],
        width       = config["plot_width"],
        fc_th       = config["fc_th"],
        ab_th       = config["ab_th"],
        pr_th       = config["pr_th"],
        sig_th      = config["sig_th"]
    message:
        "dga_humann"
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
                                                            work_dir = '{params.work_dir}', \
                                                            plot_height = {params.height}, \
                                                            plot_width = {params.width})) 2> {log}"
        """ 

#rule dga_megan:
#    input: 
#    output: 
#    run: 