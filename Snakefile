#snakemake --config yourparam=1.5
import pandas as pd
import glob

configfile: "profiles/config.yaml"

# read in samplesheet
SAMPLESHEET = pd.read_csv(config["reads"]) #.set_index("Sample", drop=False)

# set working directory
WD = {workflow.snakefile}.pop().rsplit('/', 1)[0] + '/'

# get samplenames
SAMPLE = list(SAMPLESHEET["Sample"])

# get file extensions
EXT  = '.' + SAMPLESHEET.loc[0, "R1"].rsplit(".", 2)[1]
EXT += '.' + SAMPLESHEET.loc[0, "R1"].rsplit(".", 2)[2] if SAMPLESHEET.loc[0, "R1"].rsplit(".", 1)[1] == "gz" else + ""

# set constants
READDIR     = SAMPLESHEET.loc[0, "R1"].rsplit("/", 1)[0]
RESULTDIR   = config["resultDir"] if config["resultDir"][-1] != '/' else config["resultDir"][:-1]
CACHEDIR    = config["cacheDir"] if config["cacheDir"][-1] != '/' else config["cacheDir"][:-1]
TEMPDIR     = config["tempDir"] if config["tempDir"][-1] != '/' else config["tempDir"][:-1]
#print(READDIR)

# detect read mode
SINGLE = True if pd.isna(SAMPLESHEET.loc[0, "R2"]) == 0 else False
R = ["1"] if SINGLE else ["1", "2"] 

#print("samples found:", SAMPLE)


rule all:
    input:
        expand(config["resultDir"] + "/bowtie2/{sample}_unmapped.fastq.gz", sample = SAMPLE)
        #expand(config["resultDir"] + "/concat_reads/{sample}_concat.fq", sample = SAMPLE)
    # pear
        #expand(config["resultDir"] + "/pear/{sample}.assembled.fastq", sample = SAMPLE)
    #megan
        #expand("temp/megan/{sample}.done", sample = SAMPLE)
    # diamond
        #config["cacheDir"] + "/databases/diamond/nr.dmnd"
        #expand( config["resultDir"] + "/diamond/{sample}.daa", sample = SAMPLE)
    # humann
        #config["resultDir"] + "/humann/genefamilies_"  + config["humann_count_units"] + "_combined.tsv",
        #config["resultDir"] + "/humann/pathabundance_" + config["humann_count_units"] + "_combined.tsv",
        #config["resultDir"] + "/humann/pathcoverage_combined.tsv"
        #expand("results/{sample}_{r}.{ext}.info", sample = SAMPLE, r = R, ext = EXT)
    #shell:
    #    "rm -r results"
    message:
        "rule all"

onsuccess:
    print("Workflow finished, starting cleanup..")

onerror:
    print("An error occurred, looking for temporary files to clean up..")




include: "rules/humann.smk"
include: "rules/utils.smk"
include: "rules/diamond.smk"
include: "rules/megan.smk"
include: "rules/pear.smk"
include: "rules/bowtie2.smk"

