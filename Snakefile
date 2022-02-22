import pandas as pd
import glob
import os

configfile: "profiles/config.yaml"
include: "scripts/create_input_csv.py"
include: "scripts/io.py"

if config["help"] != "dummy value": print(f"{HELPMSG}")

# read in samplesheet
if ".csv" in READS:
    # reads= is a csv file containing read info
    SAMPLESHEET = pd.read_csv(READS)
    print(f"{bcolors.OKBLUE}INFO: Loading samples from file '{READS}'.{bcolors.ENDC}")
elif READS == "":
    # reads is empty, exit
    print(f"{bcolors.FAIL}CRITICAL: No samplesheet or directory containing reads were provided to parameter 'reads='! Exiting..{bcolors.ENDC}")
    exit()
else:
    # assume whatever is in 'reads=' is the path to read dir
    print(f"{bcolors.OKBLUE}INFO: Loading samples from directory '{READS}', automatically created 'input.csv' in working directory.\n{bcolors.OKCYAN}NOTE: This requires the read mode to be set correctly. Set it with 'mode=[paired,single]'.\nRunning with read mode: {MODE}-end.{bcolors.ENDC}")
    os.system(f"python3 scripts/create_input_csv.py {READS} {MODE}")
    SAMPLESHEET = pd.read_csv("input.csv")

# set working directory
WD = {workflow.snakefile}.pop().rsplit('/', 1)[0] + '/'

# get samplenames
SAMPLE = list(SAMPLESHEET["Sample"])

# get file extensions
EXT  = '.' + SAMPLESHEET.loc[0, "R1"].rsplit(".", 2)[1]
EXT += '.' + SAMPLESHEET.loc[0, "R1"].rsplit(".", 2)[2] if SAMPLESHEET.loc[0, "R1"].rsplit(".", 1)[1] == "gz" else + ""

# check if input is fasta format -> omit fastqc checks
if "fasta" in EXT or "fna" in EXT or "fa." in EXT:
    FORMAT = "-f" #"-q" fasta:fastq
    FASTQC = False
elif "fastq" in EXT or "fq." in EXT:
    FORMAT = "-q"
else:
    print(f"{bcolors.FAIL}CRITICAL: Unknown file format detected in read file extension: {EXT}, assuming reads are in fastq format.{bcolors.ENDC}")
    FORMAT = "-q"

# set more constants
READDIR     = SAMPLESHEET.loc[0, "R1"].rsplit("/", 1)[0]
SINGLE = True if pd.isna(SAMPLESHEET.loc[0, "R2"]) == 0 else False

print(f"{bcolors.OKBLUE}INFO: Found sample files:", SAMPLE)


def rule_all_input(wildcards):

    humann  = [    os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "humann", "dga_humann.done")     ]
    megan   = [    os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "megan", "dga_megan.done")     ]
    
    if "humann" in CORETOOLS and "megan" in CORETOOLS:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tools MEGAN6 and HUMAnN 3.0 to classify input reads.{bcolors.ENDC}")
        return humann + megan

    elif "humann" in CORETOOLS:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tool HUMAnN 3.0.")
        return humann

    elif "megan" in CORETOOLS:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tool MEGAN6 to classify input reads.{bcolors.ENDC}")
        return megan

    else:
        print(f"{bcolors.FAIL}WARNING: No core tool was chosen to classify the reads. Running all core tools now..{bcolors.ENDC}")
        return humann + megan


rule all:
    input:
        rule_all_input,
        os.path.join(RESULTDIR , "Summary", "multiqc.html")
    message:
        "rule all"
    shell:
        """
        
        """


onsuccess:
    print(f"{bcolors.OKGREEN}Workflow finished successfully!\nStarting cleanup..{bcolors.ENDC}")
    if RESULTDIR != "results":
        shell(f"if [ ! -d results ]; then ln -s {RESULTDIR} results; fi")
    if CACHEDIR != "cache":
        shell(f"if [ ! -d cache ]; then ln -s {CACHEDIR} cache; fi")
    if TEMPDIR != "temp":
        shell(f"if [ ! -d temp ]; then ln -s {TEMPDIR} temp; fi")

onerror:
    print(f"{bcolors.FAIL}An error occurred, looking for temporary files to clean up..{bcolors.ENDC}")
    if RESULTDIR != "results":
        shell(f"if [ ! -d results ]; then ln -s {RESULTDIR} results; fi")
    if CACHEDIR != "cache":
        shell(f"if [ ! -d cache ]; then ln -s {CACHEDIR} cache; fi")
    if TEMPDIR != "temp":
        shell(f"if [ ! -d temp ]; then ln -s {TEMPDIR} temp; fi")


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
include: "rules/analysis.smk"



