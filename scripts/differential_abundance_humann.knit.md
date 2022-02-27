---
title: "Differential Abundance Analysis: Humann3"
author: "David Fischer"
date: "04.02.2022"
output: html_document
params:
  counts: ""
  metadata: ""
  show_code: TRUE
  comparisons: ""
  formula: "sex+antibiotic_12m+Fam_hx_stone+diet_type"
  cpus: 8
  abundance_threshold: 10
  prevalence_threshold: 0.0001
  alpha: 0.05
  fc_threshold: 1
  work_dir: ""
  plot_height: 11 
  plot_width: 11
  tool: ""
  result_dir: ""
---



### load librarys

```r
library(tidyverse)
library(broom)
library(Maaslin2)
library(foreach)
library(doParallel)
library(httr)
library(jsonlite)
library(xml2)
library(EnhancedVolcano)
library(UniProt.ws)
library(ggplot2)
library(pheatmap)
```

### load necessary files

```r
counts_df <- read.csv(file = params$counts, row.names = 1, header = TRUE, sep = '\t') 
counts_df <- counts_df[ , order(names(counts_df))]

metadata_df <- read.csv(file = params$metadata, row.names = 1, header = TRUE, sep = ',', stringsAsFactors=FALSE) %>% mutate_if(is.numeric, as.character)
metadata_df <- metadata_df[order(row.names(metadata_df)), ]

comparisons_df <- read.csv(file = params$comparisons, header = TRUE, sep = ',') 
```

### functions

```r
# create flag in case the script exits early
file.create(paste(out_dir, "dga_humann.done", sep = "/"))

plot.volcano <-function(df, title_txt, label_col, subtitle_txt){
  EnhancedVolcano(df,lab = label_col, x = "logFC", y = "qval", ylab = expression(-Log[10]~(p-value)),
                  title = title_txt, subtitle = paste("Volcano plot:", subtitle_txt, ", \u03b1 = ", params$alpha, sep = " "),
                  pCutoff = params$alpha, FCcutoff = params$fc_threshold,
                  colAlpha = 1, boxedLabels = TRUE,
                  drawConnectors = TRUE,
                  widthConnectors = 1.0,
                  colConnectors = 'black',
                  max.overlaps = 30,
                  legendLabels = c('not significant', expression(Log[2]~FC~sig), expression(adj.~p-value~sig), expression(adj.~p-value~and~log[2]~FC~sig)))
}

plot.ma <- function(df, title_txt){
  df$sig <- ifelse(df$qval < params$alpha, "1", "0")
  ggplot() +
    geom_point(data = df, aes(x = count_mean, y = logFC, col = sig), size = 0.5, show.legend = FALSE) +
    ggtitle(paste("MA-Plot:", title_txt, ", \u03b1 = ", params$alpha, sep = " ")) +
    theme(plot.title = element_text(hjust = 0.5)) +
    scale_colour_manual(values = c("1" = "red", "0" = "black")) +
    ylab("log2 fold change") +
    xlab("mean of normalized counts") 
}

plot.pca <- function(df, meta, group, title_txt){
  pca <- prcomp(t(df), center = TRUE, scale = FALSE)
  dtp <- data.frame(meta, pca$x[,1:2])
  ggplot(data = dtp) + 
       geom_point(aes(x = PC1, y = PC2, col = dtp[, group])) + 
       labs(color = group) +
       ggtitle(paste("PCA, colored by", title_txt, sep = " ")) +
       theme(plot.title = element_text(hjust = 0.5)) +
       xlab(paste0("PC1: ",   summary(pca)$importance[2,1], "% variance")) +
       ylab(paste0("PC2: ",   summary(pca)$importance[2,2] ,"% variance")) + 
       coord_fixed()
}

plot.heatmap <- function(df, n, anno, title_txt, cluster_rows = TRUE, cluster_cols = TRUE, group = NA){
  pheatmap(df[1:n, ], scale = "row", annotation_col = group, main = title_txt,
        labels_row = anno[1:n],
        labels_col = as.character(colnames(df)),
        cluster_rows = cluster_rows, 
        cluster_cols = cluster_cols)
}

plot.dist <- function(df, title_txt, group = NA, cluster_cols = FALSE, cluster_rows = FALSE){
  pheatmap(dist(df), cluster_cols = cluster_cols, cluster_rows = cluster_rows,
        scale = "row", main = title_txt,
        labels_row = as.character(rownames(df)),
        labels_col = as.character(rownames(df)),
        annotation_row = group,
        annotation_col = group)
}

uniprot.map <- function(ids1, ids2, from_str, to_str, mapping_df){

  show_col_types = FALSE

  post <- function(f, t, ids){
    show_col_types = FALSE
    response <- POST(url = "https://www.uniprot.org/uploadlists/", body = list(from = f, to = t, format = 'tab', query = paste(ids, collapse = ' ')))
    httr::content(response, type = 'text/tab-separated-values', encoding = "UTF-8")
  }
  if(length(ids1) <= 2){ return(rbind(mapping_df, post(from_str, to_str, ids1))) }
  if(length(ids1) > 5000){ return(uniprot.map(ids1[1:5000],  ids1[5001:length(ids1)], from_str, to_str, mapping_df)) }
  if(length(ids1) <= 5000){
      return(uniprot.map(ids2[1:min(length(ids2), 5000)], ids2[min(length(ids2)+1, 5001):length(ids2)], 
                  from_str, to_str, rbind(mapping_df, post(from_str, to_str, ids1)))) }
}
  
catch_empty_df <- function(df){
  if(nrow(df) <=1 ){
    write("Oopsie, seems like there is no data in here..\n This means that either the input data is empty, or all feature counts were filtered out because of low abundance or significance.\nYou can try to change the thresholds for these values [fc_th, ab_th, pr_th, sig_th] in the config file under profiles/config.yaml !", stderr())
    quit(save = "no", status = 0)
  }
}
```

### clean row and col names

```r
# clean count_df colnames (sample names)
catch_empty_df(counts_df)
colnames(counts_df) <- gsub(".RPKs", "", colnames(counts_df), fixed = TRUE)
colnames(counts_df) <- gsub("_Abundance", "", colnames(counts_df), fixed = TRUE)
```

### remove stratified duplicate hits, low abundant hits and NAs

```r
# drop stratified duplicate rows
counts_unstratified_df <- counts_df[!grepl("\\|",rownames(counts_df)),]

# drop rows containing NAs and add pseudo count to prevent MaAslin2 model fit from crashing
counts_clean_df <- na.omit(counts_unstratified_df + 1)

# remove unmapped counts
counts_clean_df <- counts_clean_df[!(row.names(counts_clean_df) %in% "UNMAPPED"), ]

# gene abundance distribution over all samples
png(filename = paste(out_dir_gen_plots, "count_distribution.png", sep = "/"), width = params$plot_width, height = params$plot_height, units = "in", res = 72)
hist_plot <- hist(rowSums(counts_clean_df[-1, ]), br = 100, main = "Cleaned gene count distribution over all samples", xlab = "Genes counts")
dev.off()
hist_plot
png(filename = paste(out_dir_gen_plots, "count_distribution_log.png", sep = "/"), width = params$plot_width, height = params$plot_height, units = "in", res = 72)
hist_log_plot <- hist(log2(rowSums(counts_clean_df[-1, ])), br = 100, main = "Log2 transformed, cleaned gene count distribution over all samples", xlab = "Log2 transformed genes counts")
dev.off()
hist_log_plot
```

### set feature display names

```r
# tell tidy to stop spamming my console with col info <3
show_col_types = FALSE

# map uniref IDs to gene name
feature_ids <- unlist(strsplit(rownames(counts_clean_df), "_"))
from <- "NF50"
if(feature_ids[1] == "UniRef90"){ from <- "NF90" }
if(feature_ids[1] == "UniRef100"){ from <- "NF100" }
feature_ids <- feature_ids[!grepl("UniRef", feature_ids)]
feature_ids <- gsub(":.*", "", feature_ids)
feature_ids <- gsub(" .*", "", feature_ids)
feature_names <- uniprot.map(feature_ids, c(), from, "GENENAME", data.frame())
write.csv(feature_names, file = paste(out_dir_gen_data, "feature_id_mapping.csv", sep = "/"))
colnames(feature_names)[1] <- "id"
colnames(feature_names)[2] <- "gene_name"


# add display names to significant features
counts_clean_df$id <- gsub(":.*", "", gsub(".*_", "", rownames(counts_clean_df)))
counts_clean_df$id <- gsub(" .*", "", counts_clean_df$id)
counts_clean_df$feature <- rownames(counts_clean_df)
counts_clean_anno_df <- merge(counts_clean_df, as.data.frame(feature_names), by = "id",  all.x = TRUE)

# do not touch this for the love of god
# add cols for gene name, synonym name and display name, where display name is whatever is available of gene name|synonym, gene name, ID in this order
counts_clean_anno_df$synonym <- ifelse(grepl(":", counts_clean_anno_df$feature), gsub(".*:", "", counts_clean_anno_df$feature), NA)
counts_clean_anno_df$display_name <- ifelse(!is.na(counts_clean_anno_df$synonym), 
                                            ifelse(!is.na(counts_clean_anno_df$gene_name),
                                                   paste(counts_clean_anno_df$gene_name, counts_clean_anno_df$synonym, sep = " | "),
                                                   paste(counts_clean_anno_df$id, counts_clean_anno_df$synonym, sep = " | ")),
                                            ifelse(!is.na(counts_clean_anno_df$gene_name),
                                                   counts_clean_anno_df$gene_name,
                                                   counts_clean_anno_df$id))

counts_clean_anno_df$feature <- gsub("[[:punct:]]", ".", counts_clean_anno_df$feature)
counts_clean_anno_df$feature <- gsub(" ", ".", counts_clean_anno_df$feature)
counts_clean_anno_df$feature <- stringr::str_trunc(counts_clean_anno_df$feature, 50)


counts_clean_anno_df <- counts_clean_anno_df[!duplicated(counts_clean_anno_df$feature), ]
rownames(counts_clean_anno_df) <- counts_clean_anno_df$feature
```

### plots on count data

```r
# sort data by most counts per row
counts_clean_anno_df <- counts_clean_anno_df[order(-rowSums(counts_clean_anno_df[ , 2:(length(counts_clean_anno_df)-4)])), ]
counts_clean_num_df <- counts_clean_anno_df[ , 2:(length(counts_clean_anno_df)-4)]

# general pca colored by sample
metadata_df$sample <- row.names(metadata_df)
pca_gen <- plot.pca(counts_clean_df[, 1:(length(colnames(counts_clean_df)) - 2)], metadata_df, "sample", "sample")
ggsave(filename = "pca_general.png", plot = pca_gen, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)
pca_gen
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-1.png" width="1056" />

```r
pca_gen_log <- plot.pca(log2(counts_clean_df[, 1:(length(colnames(counts_clean_df)) - 2)]), metadata_df, "sample", "sample")
ggsave(filename = "pca_log_general.png", plot = pca_gen_log, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)
pca_gen_log
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-2.png" width="1056" />

```r
# heatmap of top 50
heat_gen <- plot.heatmap(counts_clean_num_df, 50, counts_clean_anno_df$display_name, "Heatmap top 50 counts")
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-3.png" width="1056" />

```r
ggsave(filename = "heatmap_top_50_count_gen.png", plot = heat_gen, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)
heat_gen
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-4.png" width="1056" />

```r
heat_gen_log <- plot.heatmap(log2(counts_clean_num_df), 50, counts_clean_anno_df$display_name, "Heatmap top 50 counts")
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-5.png" width="1056" />

```r
ggsave(filename = "heatmap_top_50_count_log_gen.png", plot = heat_gen_log, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)
heat_gen_log
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-6.png" width="1056" />

```r
# sample to sample distance
sample_dist <- plot.dist(t(counts_clean_num_df), "Sample to sample count distance (euclidean)")
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-7.png" width="1056" />

```r
ggsave(filename = "sample_to_sample_dist_count.png", plot = sample_dist, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)
sample_dist
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-8.png" width="1056" />

```r
sample_dist_log <- plot.dist(t(log2(counts_clean_num_df)), "Sample to sample log count distance (euclidean)")
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-9.png" width="1056" />

```r
ggsave(filename = "sample_to_sample_dist_log_count.png", plot = sample_dist_log, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)
sample_dist_log
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/count_plots-10.png" width="1056" />

### run MaAslin2 model for given formula

```r
# clean metadata rownames (sample names)
catch_empty_df(metadata_df)
row.names(counts_clean_df) <- gsub("[[:punct:]]", ".", row.names(counts_clean_df))
row.names(counts_clean_df) <- gsub(" ", ".", row.names(counts_clean_df))

# set reference level for each condition assuming first occurence is reference for now
ref_levels <- c()
conditions <- strsplit(params$formula, "\\+")[[1]]
for(i in 1:length(conditions)){
  ref_levels <- rbind(ref_levels, paste(conditions[i], metadata_df[1, conditions[i]], sep = ","))
}

# run model once for given formula, assume first entry in metadata is the reference level
sink("/dev/null") # make maaslin2 shut up for once
fit <- Maaslin2(
    input_data = counts_clean_anno_df, 
    input_metadata = metadata_df, 
    output = paste(out_dir_gen_data, "maaslin2_model_output", sep = "/"),
    analysis_method = "CPLM",
    normalization = "NONE",
    transform = "NONE",
    fixed_effects = strsplit(params$formula, "\\+")[[1]],
    reference = paste(ref_levels, collapse = ";"),
    cores = params$cpus,
    min_abundance = params$abundance_threshold,
    min_prevalence = params$prevalence_threshold,
    plot_scatter = FALSE)
sink() 

results_df <- fit$results
results_df <- na.omit(results_df)
catch_empty_df(results_df)
results_df <- merge(results_df, counts_clean_anno_df, all.x = TRUE, by = "feature")
results_df <- mutate(results_df, count_mean = rowMeans(results_df[ , 12:(length(results_df)-3)]))
results_df <- mutate(results_df, logFC = log2(exp(results_df$coef))) 

ma_plot_gen <- plot.ma(results_df, "all groups")
ggsave(filename = "ma_plot_general.png", plot = ma_plot_gen, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)

volcano_plot_gen <- plot.volcano(results_df, "Total differential abundant features", results_df$display_name, "all groups")
ggsave(filename = "volcano_plot_general.png", plot = volcano_plot_gen, device = png, path = out_dir_gen_plots, width = 15, height = 10)
```

### general analysis results

```r
res_ordered <- results_df[order(-abs(results_df$logFC), results_df$qval), ]
table_df <- res_ordered[ , c("display_name", "value", "logFC", "qval", "count_mean")]
knitr::kable(table_df[1:min(nrow(table_df), 50), ], col.names = c('feature name', 'condition', 'log fold change', 'adj. p-value', 'norm. counts mean'))
```



|   |feature name                                                           |condition | log fold change| adj. p-value| norm. counts mean|
|:--|:----------------------------------------------------------------------|:---------|---------------:|------------:|-----------------:|
|16 |HMPREF0880_02691                                                       |treatment |     -11.0070148|    0.4397794|          956.4850|
|1  |A6M23_06185                                                            |treatment |      -1.9736860|    1.0000000|          450.1605|
|7  |HMPREF0880_00179                                                       |treatment |      -1.4995670|    1.0000000|         1319.8975|
|10 |HMPREF0880_00552                                                       |treatment |      -1.4995670|    1.0000000|         1319.8975|
|28 |grdA2 &#124;  Glycine/sarcosine/betaine reductase complex component A2 |treatment |      -0.9472144|    1.0000000|          929.4375|
|5  |rpmH                                                                   |treatment |      -0.7928096|    1.0000000|          840.8587|
|17 |HMPREF0880_02786                                                       |treatment |      -0.7560933|    1.0000000|         2310.9375|
|25 |HMPREF0880_04766                                                       |treatment |      -0.7560933|    1.0000000|         2310.9375|
|20 |HMPREF0880_03700                                                       |treatment |       0.6048578|    1.0000000|         1205.5675|
|14 |HMPREF0880_02032                                                       |treatment |      -0.6011364|    1.0000000|          999.0620|
|3  |crl_1                                                                  |treatment |      -0.5192934|    1.0000000|         2524.4625|
|9  |HMPREF0880_00356                                                       |treatment |      -0.3941507|    1.0000000|          842.1550|
|18 |HMPREF0880_02866                                                       |treatment |      -0.3941507|    1.0000000|          842.1550|
|24 |HMPREF0880_04720                                                       |treatment |      -0.3941507|    1.0000000|          842.1550|
|26 |UUU_05910                                                              |treatment |      -0.3941507|    1.0000000|          842.1550|
|29 |EDP2_1152                                                              |treatment |      -0.3941507|    1.0000000|          842.1550|
|21 |HMPREF0880_03934                                                       |treatment |      -0.3939921|    1.0000000|          631.8675|
|8  |HMPREF0880_00295                                                       |treatment |      -0.3244819|    1.0000000|         1321.7640|
|12 |HMPREF0880_01557                                                       |treatment |      -0.2473080|    1.0000000|         2674.3500|
|22 |HMPREF0880_03949                                                       |treatment |      -0.2198835|    1.0000000|         1127.3865|
|4  |A0A377T6U1                                                             |treatment |      -0.1801856|    1.0000000|         1833.1950|
|6  |LTSESEN_5372                                                           |treatment |       0.1389680|    1.0000000|          739.3858|
|23 |HMPREF0880_04537                                                       |treatment |      -0.0864226|    1.0000000|          954.5685|
|27 |mntS &#124;  Small protein MntS                                        |treatment |       0.0000000|    1.0000000|         1983.0750|
|2  |A0A2A7PRR7                                                             |treatment |       0.0000000|    1.0000000|          992.0400|
|11 |HMPREF0880_01538                                                       |treatment |       0.0000000|    1.0000000|          992.0400|
|13 |HMPREF0880_01844                                                       |treatment |       0.0000000|    1.0000000|          992.0400|
|15 |HMPREF0880_02503                                                       |treatment |       0.0000000|    1.0000000|          567.3050|
|19 |HMPREF0880_03629                                                       |treatment |       0.0000000|    1.0000000|          744.2800|

```r
write.csv(table_df[1:min(nrow(table_df), 50), ], file = paste(out_dir_gen_data, "top_50_significantly_expressed_features.csv", sep = "/"))
```

### run comparisons

```r
logFC_by_cond <- as.data.frame(rownames(counts_clean_anno_df))
colnames(logFC_by_cond)[1] <- "feature"

cl <- makeCluster(min(params$cpus, nrow(comparisons_df)))
registerDoParallel(cl)

worker_array <- foreach(i = 1:nrow(comparisons_df), .errorhandling='pass', .verbose=TRUE, .packages = c("Maaslin2", "EnhancedVolcano", "pheatmap", "tidyverse", "doParallel")) %dopar% {
  
  cond <- comparisons_df$Condition[i]
  ref <- comparisons_df$Group1[i]
  alt <- comparisons_df$Group2[i]
  
  # create directory structure for current contrast 
  contrast <- paste(ref, "vs", alt, sep = "_")
  out_dir_curr <- paste(out_dir_con, contrast, sep = "/")
  dir.create(out_dir_curr, showWarnings = FALSE)
  
  out_dir_curr_plots <- paste(out_dir_curr, "Plots", sep = "/")
  dir.create(out_dir_curr_plots, showWarnings = FALSE)
  
  out_dir_curr_data <- paste(out_dir_curr, "Data", sep = "/")
  dir.create(out_dir_curr_data, showWarnings = FALSE)
  
  # set reference level with this 'hack' because the reference option will not work for binary conditions -.-
  metadata_con_df <- metadata_df
  metadata_con_df[[cond]] <- ifelse(grepl(ref, metadata_con_df[[cond]]), paste0("aa", metadata_con_df[[cond]]),  metadata_con_df[[cond]])

  # run model once for each contrast, assume Group1 from contrast sheet is the reference level
  sink("/dev/null") # make maaslin2 shut up for once
  fit <- Maaslin2(
      input_data = counts_clean_anno_df, 
      input_metadata = metadata_con_df, 
      output = paste(out_dir_curr_data, paste(contrast, "maaslin2_model_output", sep = "_"), sep = "/"),
      analysis_method = "CPLM",
      normalization = "NONE",
      transform = "NONE",
      fixed_effects = cond,
      cores = 1,
      min_abundance = params$abundance_threshold,
      min_prevalence = params$prevalence_threshold,
      plot_scatter = FALSE)
  sink() 
  
  # select rows with current condition
  results_cond_df <- fit$results
  
  # get display names, logFC and mean of normalized counts
  results_cond_df <- merge(results_cond_df, counts_clean_anno_df, all.x = TRUE, by = "feature")
  results_cond_df <- mutate(results_cond_df, count_mean = rowMeans(results_cond_df[ , 12:(length(results_cond_df)-3)]))
  results_cond_df <- mutate(results_cond_df, logFC = log2(exp(results_cond_df$coef)))
  
  # save logFC for this contrast for later heatmap
  temp <- as.data.frame(results_cond_df[results_cond_df$value %in% alt  , "logFC"])
  temp$feature <- results_cond_df[results_cond_df$value %in% alt  , "feature"]
  temp$qval <- results_cond_df[results_cond_df$value %in% alt  , "qval"]
  colnames(temp)[c(1,2,3)] <- c(contrast, "feature", paste("qval", contrast, sep = "_"))
  export <- merge(logFC_by_cond, temp, by = "feature", all = TRUE)

  # filter for significance
  res_sig_df <- results_cond_df[ results_cond_df$qval < params$alpha, ]
  if(nrow(res_sig_df) < 2){stop()}
  
  # order by ascending adjusted pval and descending logFC
  res_sig_ordered_df <- res_sig_df[order(res_sig_df$qval, -abs(res_sig_df$logFC)), ]

  # get top 100 significant features ordered by logFC
  top_100_df <- res_sig_ordered_df[1:min(nrow(res_sig_ordered_df), 100), ]
  write.csv(top_100_df, file = paste(out_dir_curr_data, paste(contrast, "top_100_features.csv", sep = "_"), sep = "/"))

  try({
    # plot pca colored by current condition
    pca_con <- plot.pca(counts_clean_df[, 1:(length(colnames(counts_clean_df)) - 2)], metadata_df, cond, cond)
    bin <- ggsave(filename = paste(contrast, "pca.png", sep = "/"), plot = pca_con, device = png, path = out_dir_curr_plots, height = params$plot_height, width = params$plot_width)
    pca_con_log <- plot.pca(log2(counts_clean_df[, 1:(length(colnames(counts_clean_df)) - 2)]), metadata_df, cond, cond)
    bin <- ggsave(filename = paste(contrast, "pca_log.png", sep = "/"), plot = pca_con_log, device = png, path = out_dir_curr_plots, height = params$plot_height, width = params$plot_width)
  }, silent=FALSE)

  # heatmap of top 50
  top_100_anno_df <- merge(top_100_df, counts_clean_anno_df, all.x = TRUE, by = "row.names")
  top_100_num_df <- top_100_anno_df[ , 3:(ncol(top_100_anno_df)-14)]
  
  try({
    groups <- data.frame(metadata_df[[cond]])
    colnames(groups)[1] <- cond
    rownames(groups) <- rownames(metadata_df)
    heat_con <- plot.heatmap(top_100_num_df, min(nrow(top_100_num_df), 50), top_100_anno_df$display_name, paste("Heatmap of top 50 significant feature counts by logFC colored by", cond, sep = " "), group = groups)
    bin <- ggsave(filename = paste(contrast, "heatmap_top_50_count_by_FC.png", sep = "_"), plot = heat_con, device = png, path = out_dir_curr_plots, height = params$plot_height, width = params$plot_width)
    heat_con_log <- plot.heatmap(log2(counts_clean_num_df), min(nrow(top_100_num_df), 50), top_100_anno_df$display_name, paste("Heatmap of top 50 significant feature counts by logFC colored by", cond, "(log)", sep = " "), group = groups)
    bin <- ggsave(filename = paste(contrast, "heatmap_top_50_log_count_by_FC.png", sep = "_"), plot = heat_con_log, device = png, path = out_dir_curr_plots, height = params$plot_height, width = params$plot_width)
  }, silent=TRUE)

  try({
    # sample to sample distance
    sample_dist_con <- plot.dist(t(top_100_num_df), paste("Sample to sample count distance colored by ", cond, "(euclidean)", sep = " "), group = groups, TRUE, TRUE)
    bin <- ggsave(filename = paste(contrast, "sample_to_sample_dist_count.png", sep = "_"), plot = sample_dist_con, device = png, path = out_dir_curr_plots, height = params$plot_height, width = params$plot_width)
    sample_dist_log <- plot.dist(t(log2(counts_clean_num_df)), paste("Sample to sample log count distance colored by ", cond, "(euclidean)", sep = " "), group = groups, TRUE, TRUE)
    bin <- ggsave(filename = paste(contrast, "sample_to_sample_dist_log_count.png", sep = "_"), plot = sample_dist_log, device = png, path = out_dir_curr_plots, height = params$plot_height, width = params$plot_width)
  }, silent=TRUE)

  try({
    # volcano plot for current contrast
    volcano_plot_con <- plot.volcano(results_cond_df[results_cond_df$value %in% alt , ], "Differential abundant features by contrast", results_cond_df[results_cond_df$value %in% alt  , "display_name"], contrast)
    bin <- ggsave(filename = paste(contrast, "volcano_plot.png", sep = "_"), plot = volcano_plot_gen, device = png, path = out_dir_curr_plots, width = 15, height = 10)
  }, silent=TRUE)
  
  try({
    # ma-plot for current contrast
    ma_plot_con <- plot.ma(results_cond_df, contrast)
    bin <- ggsave(filename = paste(contrast, "ma_plot.png", sep = "_"), plot = ma_plot_con, device = png, path = out_dir_curr_plots, height = params$plot_height, width = params$plot_width)
  }, silent=TRUE)

  export
}

stopCluster(cl)
```

### summarize per-contrast output

```r
for(i in 1:length(worker_array)){ 
  if(is.data.frame(worker_array[[i]])){
    logFC_by_cond <- merge(logFC_by_cond, worker_array[[i]], by = "feature")
  }
}
rownames(logFC_by_cond) <- logFC_by_cond$feature
logFC_by_cond <- logFC_by_cond[-1]

# remove rows with only NA
logFC_by_cond <- logFC_by_cond[rowSums(is.na(logFC_by_cond)) != ncol(logFC_by_cond), ]
catch_empty_df(logFC_by_cond)
logFC_by_cond[is.na(logFC_by_cond)] <- 1

# sort by ascending qval and descending abs(logFC)
logFC_by_cond <- logFC_by_cond[order(-rowSums(abs(logFC_by_cond[ , seq(1, ncol(logFC_by_cond), 2)])),
                                     rowSums(logFC_by_cond[ , seq(2, ncol(logFC_by_cond), 2)])), ]
logFC_by_cond_num <- logFC_by_cond[ , seq(1, ncol(logFC_by_cond), 2)]
logFC_by_cond_num[logFC_by_cond_num == 1] <- 0

write.csv(logFC_by_cond, file = paste(out_dir_gen_data, "logFC_per_contrast.csv", sep = "/"))
knitr::kable(logFC_by_cond[1:min(nrow(logFC_by_cond), 50), ])
```



|                                                   | treatment_vs_control| qval_treatment_vs_control| control_vs_treatment| qval_control_vs_treatment|
|:--------------------------------------------------|--------------------:|-------------------------:|--------------------:|-------------------------:|
|UniRef50.G9Z5A2                                    |           11.0070148|                 0.4397794|          -11.0070148|                 0.4397794|
|UniRef50.A0A1C2IEP4                                |            1.9736860|                 1.0000000|           -1.9736860|                 1.0000000|
|UniRef50.G9YY89                                    |            1.4995670|                 1.0000000|           -1.4995670|                 1.0000000|
|UniRef50.G9YZA7                                    |            1.4995670|                 1.0000000|           -1.4995670|                 1.0000000|
|UniRef50.Q6LH19..Glycine.sarcosine.betaine.redu... |            0.9472144|                 1.0000000|           -0.9472144|                 1.0000000|
|UniRef50.C0ZVP8                                    |            0.7928096|                 1.0000000|           -0.7928096|                 1.0000000|
|UniRef50.G9Z5U1                                    |            0.7560933|                 1.0000000|           -0.7560933|                 1.0000000|
|UniRef50.G9ZB48                                    |            0.7560933|                 1.0000000|           -0.7560933|                 1.0000000|
|UniRef50.G9Z856                                    |           -0.6048578|                 1.0000000|            0.6048578|                 1.0000000|
|UniRef50.G9Z3N8                                    |            0.6011364|                 1.0000000|           -0.6011364|                 1.0000000|
|UniRef50.A0A376U2I3                                |            0.5192934|                 1.0000000|           -0.5192934|                 1.0000000|
|UniRef50.G9YYR9                                    |            0.3941507|                 1.0000000|           -0.3941507|                 1.0000000|
|UniRef50.G9Z6B8                                    |            0.3941507|                 1.0000000|           -0.3941507|                 1.0000000|
|UniRef50.G9ZB04                                    |            0.3941507|                 1.0000000|           -0.3941507|                 1.0000000|
|UniRef50.J2XCU8                                    |            0.3941507|                 1.0000000|           -0.3941507|                 1.0000000|
|UniRef50.V5B655                                    |            0.3941507|                 1.0000000|           -0.3941507|                 1.0000000|
|UniRef50.G9Z8F3                                    |            0.3939921|                 1.0000000|           -0.3939921|                 1.0000000|
|UniRef50.G9YYK8                                    |            0.3244819|                 1.0000000|           -0.3244819|                 1.0000000|
|UniRef50.G9Z249                                    |            0.2473080|                 1.0000000|           -0.2473080|                 1.0000000|
|UniRef50.G9Z8G6                                    |            0.2198835|                 1.0000000|           -0.2198835|                 1.0000000|
|UniRef50.A0A377T6U1                                |            0.1801856|                 1.0000000|           -0.1801856|                 1.0000000|
|UniRef50.G5R6P8                                    |           -0.1389680|                 1.0000000|            0.1389680|                 1.0000000|
|UniRef50.G9ZAH6                                    |            0.0864226|                 1.0000000|           -0.0864226|                 1.0000000|
|UniRef50.P0DKB3..Small.protein.MntS                |            0.0000000|                 1.0000000|            0.0000000|                 1.0000000|
|UniRef50.G9Z7T7                                    |            0.0000000|                 1.0000000|            0.0000000|                 1.0000000|
|UniRef50.G9Z4G0                                    |            0.0000000|                 1.0000000|            0.0000000|                 1.0000000|
|UniRef50.A0A2A7PRR7                                |            0.0000000|                 1.0000000|            0.0000000|                 1.0000000|
|UniRef50.G9Z230                                    |            0.0000000|                 1.0000000|            0.0000000|                 1.0000000|
|UniRef50.G9Z348                                    |            0.0000000|                 1.0000000|            0.0000000|                 1.0000000|

```r
# get display names
logFC_by_cond <- merge(logFC_by_cond, counts_clean_anno_df, by.x = 0, by.y = 0, all.x = TRUE)

# heatmap of top significant and expressed features by contrasts
heat_FC <- plot.heatmap(logFC_by_cond_num, min(nrow(logFC_by_cond_num), 50), logFC_by_cond$display_name, "Heatmap of top 50 significant, expressed features by contrasts")
ggsave(filename = "heatmap_top_50_FC_by_contrast.png", plot = heat_FC, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)
heat_FC
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/summary_output-1.png" width="1056" />

```r
# pca of top significant and expressed features by contrasts
temp <- as.data.frame(colnames(logFC_by_cond_num))
colnames(temp)[1] <- "contrast"
pca_FC <- plot.pca(logFC_by_cond_num, temp, "contrast", "contrast")
ggsave(filename = "contrasts_pca.png", plot = pca_FC, device = png, path = out_dir_gen_plots, height = params$plot_height, width = params$plot_width)
pca_FC
```

<img src="../results/04-DifferentialGeneAbundance/humann/dga_humann_files/figure-html/summary_output-2.png" width="1056" />