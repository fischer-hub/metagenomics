rule dga_humann:
    input: 
        expand(RESULTDIR + "/humann/norm/{sample}_genefamilies_"  + UNITS + ".tsv", sample = SAMPLE)
    output: 
    conda:
        "../envs/analysis.yaml"
    shell:
        """
        Rscript -e "rmarkdown::render('differential_abundance_humann.Rmd',params=list(counts = '/home/david/bachelorarbeit/metagenomics/assets/genefamilies_cpm_combined.tsv', metadata = '/home/david/bachelorarbeit/metagenomics/assets/SraRunTable.txt', show_code = FALSE, comparisons = '/home/david/bachelorarbeit/metagenomics/assets/contrast.csv', formula = 'sex+antibiotic_12m+Fam_hx_stone+diet_type', cpus = 8, abundance_threshold = 10, prevalence_threshold = 0.0001, alpha = 0.9, fc_threshold = 1, work_dir = '/home/david/abundance_analysis', plot_height = 11, plot_width = 11))"
        """ 

#rule dga_megan:
#    input: 
#    output: 
#    run: 