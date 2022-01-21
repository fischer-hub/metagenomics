#snakemake --config yourparam=1.5
import pandas as pd
import glob
import os

configfile: "profiles/config.yaml"
include: "scripts/create_input_csv.py"
include: "scripts/io.py"


param_reads = config["reads"]

# read in samplesheet
if ".csv" in param_reads:
    # reads= is a csv file containing read info
    SAMPLESHEET = pd.read_csv(param_reads)
    print(f"{bcolors.OKBLUE}INFO: Loading samples from file '{param_reads}'.")
elif config["reads"] == "":
    # reads is empty, exit
    print(f"{bcolors.FAIL}CRITICAL: No samplesheet or directory containing reads were provided to parameter 'reads='! Exiting..")
    exit()
else:
    # assume whatever is in 'reads=' is the path to read dir
    print(f"{bcolors.OKBLUE}INFO: Loading samples from directory '{param_reads}', automatically created 'input.csv' in work directory.")
    os.system(f"python3 scripts/create_input_csv.py {param_reads}")
    SAMPLESHEET = pd.read_csv("input.csv")

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

print("samples found:", SAMPLE)

def rule_all_input(wildcards):
    
    if "humann" in config["tools"] and "megan" in config["tools"]:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tools MEGAN6 and HUMAnN 3.0 to classify input reads.")
        return [    config["resultDir"] + "/humann/genefamilies_"  + config["humann_count_units"] + "_combined.tsv",
                    config["resultDir"] + "/humann/pathabundance_" + config["humann_count_units"] + "_combined.tsv",
                    config["resultDir"] + "/humann/pathcoverage_combined.tsv", 
                    config["resultDir"] + "/megan/megan_combined.csv"   ]
    elif "humann" in config["tools"]:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tool HUMAnN 3.0.")
        return [    config["resultDir"] + "/humann/genefamilies_"  + config["humann_count_units"] + "_combined.tsv",
                    config["resultDir"] + "/humann/pathabundance_" + config["humann_count_units"] + "_combined.tsv",
                    config["resultDir"] + "/humann/pathcoverage_combined.tsv"   ]
    elif "megan" in config["tools"]:
        print(f"{bcolors.OKGREEN}Running pipeline with core tool MEGAN6 to classify input reads.")
        return [    config["resultDir"] + "/megan/megan_combined.csv"   ]
    else:
        print(f"{bcolors.FAIL}WARNING: No core tool was chosen to classify the reads.")
        return []

rule all:
    input:
        rule_all_input
    message:
        "rule all"
    shell:
        "echo 'clean up'"

onsuccess:
    print("Workflow finished, starting cleanup..")
    if RESULTDIR != "results":
        shell(f"if [ ! -d results ]; then ln -s {RESULTDIR} results; fi")

onerror:
    print("An error occurred, looking for temporary files to clean up..")


include: "rules/humann.smk"
include: "rules/utils.smk"
include: "rules/diamond.smk"
include: "rules/megan.smk"
include: "rules/pear.smk"
include: "rules/bowtie2.smk"
include: "rules/trimmomatic.smk"
include: "rules/fastqc.smk"


