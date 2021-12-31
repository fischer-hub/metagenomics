#snakemake --config yourparam=1.5
import pandas as pd

# read in samplesheet
SAMPLESHEET = pd.read_csv(config["reads"]) #.set_index("Sample", drop=False)

# set working directory
WD = {workflow.snakefile}.pop().rsplit('/', 1)[0] + '/'

# get samplenames
SAMPLE = list(SAMPLESHEET["Sample"])

# get file extensions
EXT = '.' + SAMPLESHEET.loc[0, "R1"].rsplit(".", 2)[1]
EXT += '.' + SAMPLESHEET.loc[0, "R1"].rsplit(".", 2)[2] if SAMPLESHEET.loc[0, "R1"].rsplit(".", 1)[1] == "gz" else + ""


READDIR = SAMPLESHEET.loc[0, "R1"].rsplit("/", 1)[0]
print(READDIR)

# detect read mode
SINGLE = True if pd.isna(SAMPLESHEET.loc[0, "R2"]) == 0 else False
R = ["1"] if SINGLE else ["1", "2"] 

print("samples found:", SAMPLE)

rule all:
    input:
        config["resultDir"] + "/humann/genefamilies_relab_combined.tsv",
        config["resultDir"] + "/humann/pathabundance_combined.tsv",
        config["resultDir"] + "/humann/pathcoverage_combined.tsv"
        #expand("results/{sample}_{r}.{ext}.info", sample = SAMPLE, r = R, ext = EXT)
    #shell:
    #    "rm -r results"

configfile: "profiles/config.yaml"

include: "rules/humann.smk"
include: "rules/utils.smk"