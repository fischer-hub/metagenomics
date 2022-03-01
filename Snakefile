import pandas as pd
import os, shutil, yaml, glob

configfile: "profiles/config.yaml"
include: "scripts/create_input_csv.py"
include: "scripts/io.py"
include: "rules/common.smk"

if config["help"] != "dummy value" :
    print(f"{HELPMSG}")
    exit()

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

# get samplenames
SAMPLE = list(SAMPLESHEET["Sample"])

# get file extensions
EXT  = f".{SAMPLESHEET.loc[0, 'R1'].rsplit('.', 2)[1]}"
EXT  = f"{EXT}.{SAMPLESHEET.loc[0, 'R1'].rsplit('.', 2)[2]}" if SAMPLESHEET.loc[0, "R1"].rsplit(".", 1)[1] == "gz" else EXT

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

rule all:
    input:
        rule_all_input,
        os.path.join(RESULTDIR , "05-Summary", "multiqc.html")
    params:
        results = lambda w, input: input[0].split("05-Summary")[0],
        clean   = CLEAN,
        tmp     = TEMPDIR
    message:
        "rule all"
    log:
        os.path.join(RESULTDIR, "00-Log", "rule_all.log")
    run:
        try:
            os.remove("Rplots.pdf")
            os.remove(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "humann", "dga_humann.done"))
            os.remove(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "megan", "dga_megan.done"))
        except OSError:
            pass


onsuccess:
    print(f"{bcolors.OKGREEN}Workflow finished successfully!\nStarting cleanup..{bcolors.ENDC}")
    if RESULTDIR != "results":
        shell(f"if [ ! -d results ]; then ln -s {RESULTDIR} results; fi")
    if CACHEDIR != "cache":
        shell(f"if [ ! -d cache ]; then ln -s {CACHEDIR} cache; fi")
    if TEMPDIR != "temp" and CLEAN != "true":
        shell(f"if [ ! -d temp ]; then ln -s {TEMPDIR} temp; fi")
    if CLEAN == "true":
        try:
            os.remove(TEMPDIR)
            shutil.move(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "humann","dga_humann.html"), os.path.join(RESULTDIR, "05-Summary", "dga_report_humann.html"))
            shutil.move(os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "megan","dga_megan.html"), os.path.join(RESULTDIR, "05-Summary", "dga_report_megan.html"))
        except OSError:
            pass

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



