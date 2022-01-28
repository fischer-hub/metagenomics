#snakemake --config yourparam=1.5
import pandas as pd
import glob
import os
import timeit

start = timeit.default_timer()

configfile: "profiles/config.yaml"
include: "scripts/create_input_csv.py"
include: "scripts/io.py"

print(f"{BANNER}")

param_reads = config["reads"]
param_mode = config["mode"]
MERGER = config["merger"] if param_mode == "paired" else "none"
FASTQC = config["fastqc"]
FORMAT = "-f" #"-q" fasta:fastq

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
    print(f"{bcolors.OKBLUE}INFO: Loading samples from directory '{param_reads}', automatically created 'input.csv' in work directory.\n{bcolors.OKCYAN}NOTE: This requires the read mode to be set correctly. Set it with 'mode=[paired,single]'.\nRunning with read mode: {param_mode}-end.")
    os.system(f"python3 scripts/create_input_csv.py {param_reads} {param_mode}")
    SAMPLESHEET = pd.read_csv("input.csv")

# set working directory
WD = {workflow.snakefile}.pop().rsplit('/', 1)[0] + '/'

# get samplenames
SAMPLE = list(SAMPLESHEET["Sample"])

# get file extensions
EXT  = '.' + SAMPLESHEET.loc[0, "R1"].rsplit(".", 2)[1]
EXT += '.' + SAMPLESHEET.loc[0, "R1"].rsplit(".", 2)[2] if SAMPLESHEET.loc[0, "R1"].rsplit(".", 1)[1] == "gz" else + ""

# check if input is fasta format -> omit fastqc checks
if "fasta" in SAMPLESHEET.loc[0, "R1"]:
    FASTQC = False

# set constants
READDIR     = SAMPLESHEET.loc[0, "R1"].rsplit("/", 1)[0]
RESULTDIR   = config["resultDir"] if config["resultDir"][-1] != '/' else config["resultDir"][:-1]
CACHEDIR    = config["cacheDir"] if config["cacheDir"][-1] != '/' else config["cacheDir"][:-1]
TEMPDIR     = config["temp"] if config["temp"][-1] != '/' else config["temp"][:-1]
#print(READDIR)

# detect read mode
SINGLE = True if pd.isna(SAMPLESHEET.loc[0, "R2"]) == 0 else False
R = ["1"] if SINGLE else ["1", "2"] 

print(f"{bcolors.OKBLUE}INFO: Found sample files:", SAMPLE)

def rule_all_input(wildcards):
    
    if "humann" in config["tools"] and "megan" in config["tools"]:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tools MEGAN6 and HUMAnN 3.0 to classify input reads.{bcolors.OKBLUE}")
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
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tool MEGAN6 to classify input reads.{bcolors.OKGREEN}")
        return [    config["resultDir"] + "/megan/megan_combined.csv"   ]
    else:
        print(f"{bcolors.FAIL}WARNING: No core tool was chosen to classify the reads. Running all core tools now..{bcolors.FAIL}")
        return [    config["resultDir"] + "/humann/genefamilies_"  + config["humann_count_units"] + "_combined.tsv",
                    config["resultDir"] + "/humann/pathabundance_" + config["humann_count_units"] + "_combined.tsv",
                    config["resultDir"] + "/humann/pathcoverage_combined.tsv", 
                    config["resultDir"] + "/megan/megan_combined.csv"   ]

rule all:
    input:
        rule_all_input,
        RESULTDIR + "/Summary/multiqc.html"
    message:
        "rule all"
    shell:
        "echo 'clean up'"


stop = timeit.default_timer()

onsuccess:
    print(f"{bcolors.OKGREEN}Workflow finished successfully!\nTotal time passed: {stop - start}\nStarting cleanup..{bcolors.ENDC}")
    if RESULTDIR != "results":
        shell(f"if [ ! -d results ]; then ln -s {RESULTDIR} results; fi")

onerror:
    print("An error occurred, looking for temporary files to clean up..")
    if RESULTDIR != "results":
        shell(f"if [ ! -d results ]; then ln -s {RESULTDIR} results; fi")


include: "rules/humann.smk"
include: "rules/utils.smk"
include: "rules/diamond.smk"
include: "rules/megan.smk"
include: "rules/pear.smk"
include: "rules/bowtie2.smk"
include: "rules/trimmomatic.smk"
include: "rules/fastqc.smk"
include: "rules/multiqc.smk"
include: "rules/bbmerge.smk"



