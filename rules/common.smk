def rule_all_input(wildcards):

    humann  = [    os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "humann", "dga_humann.done")     ]
    megan   = [    os.path.join(RESULTDIR, "04-DifferentialGeneAbundance", "megan", "dga_megan.done")     ]
    #compare = [    os.path.join(RESULTDIR, "03-CountData", "humann", f"genefamilies_{UNITS}_combined_eggNOG.tsv")   ]
    compare = [    os.path.join(RESULTDIR, "03-CountData", "humann", "logFC_combined_eggNOG.tsv")   ]

    if "humann" in CORETOOLS and "megan" in CORETOOLS:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tools MEGAN6 and HUMAnN 3.0 to classify input reads.{bcolors.ENDC}")
        return humann + megan + compare

    elif "humann" in CORETOOLS:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tool HUMAnN 3.0.")
        return humann

    elif "megan" in CORETOOLS:
        print(f"{bcolors.OKBLUE}INFO: Running pipeline with core tool MEGAN6 to classify input reads.{bcolors.ENDC}")
        return megan

    else:
        print(f"{bcolors.FAIL}WARNING: No core tool was chosen to classify the reads. Running all core tools now..{bcolors.ENDC}")
        return humann + megan + compare


def dga_counts(wildcards):

    humann  = [ os.path.join(RESULTDIR, "03-CountData", "humann", f"genefamilies_{UNITS}_combined.tsv")   ]
    megan   = [ os.path.join(RESULTDIR, "03-CountData", "megan", "megan_combined.csv")    ]

    if wildcards.tool == "humann": return humann
    else: return megan
    

def merge_input(wildcards):
    if TRIM == "true":
        return  {   "R1" : os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{wildcards.sample}_1.fastq.gz".format(wildcards=wildcards)),
                    "R2" : os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{wildcards.sample}_2.fastq.gz".format(wildcards=wildcards))    }
    else:
        return  {   "R1" : os.path.join(READDIR, "{wildcards.sample}_1".format(wildcards=wildcards), EXT),
                    "R2" : os.path.join(READDIR, "{wildcards.sample}_2".format(wildcards=wildcards), EXT)   }


def get_humann_reads(wildcards):
    if REFERENCE != "":
        return os.path.join(RESULTDIR, "02-Decontamination", "{wildcards.sample}_unmapped.fastq.gz".format(wildcards=wildcards))
    else:
        return os.path.join(TEMPDIR, "concat_reads", "{wildcards.sample}_concat.fq.gz".format(wildcards=wildcards))


def get_bowtie_reads(wildcards):
    if MODE == "paired":
        return os.path.join(TEMPDIR, "concat_reads", "{wildcards.sample}_concat.fq.gz".format(wildcards=wildcards))
    elif TRIM == "true":
        return os.path.join(RESULTDIR, "01-QualityControl", "trimmed_se", "{wildcards.sample}.fastq.gz".format(wildcards=wildcards))
    else:
        return os.path.join(READDIR, "{wildcards.sample}".format(wildcards=wildcards), EXT)


def get_references(wildcards):
    file_paths = []
    for file in glob.glob(f"{REFERENCE}/*"):
        file_paths.append(file)
    return file_paths


def get_diamond_reads(wildcards):
    if REFERENCE != "":
        return os.path.join(RESULTDIR, "02-Decontamination", "{wildcards.sample}_unmapped.fastq.gz".format(wildcards=wildcards))
    else:
        return os.path.join(RESULTDIR, "concat_reads", "{wildcards.sample}_concat.fq.gz".format(wildcards=wildcards))


def get_reports(wildcards):

    reports = []
    if MERGER == "bbmerge":
        reports.extend(expand(os.path.join(TEMPDIR, "bbmerge", "{sample}_ihist.txt"), sample = SAMPLE))

    if REFERENCE != "":
        reports.extend(expand(os.path.join(RESULTDIR, "00-Log", "bowtie2", "bowtie2_map_{sample}.log"), sample = SAMPLE))

    if FASTQC and MODE == "paired":
        reports.extend(expand(os.path.join(TEMPDIR, "qc", "fastqc_pre", "{sample}_{mate}_fastqc.zip"), sample = SAMPLE, mate = ["1", "2"]))
    if FASTQC and MODE == "single":
        reports.extend(expand(os.path.join(TEMPDIR, "qc", "fastqc_se", "{sample}_fastqc.zip"), sample = SAMPLE))

    return reports


def get_concat_input(wildcards):
    if MERGER == "pear":
        return  [   os.path.join(RESULTDIR, "01-QualityControl", "merged", "{wildcards.sample}.assembled.fastq".format(wildcards=wildcards)),
                    os.path.join(RESULTDIR, "01-QualityControl", "merged", "{wildcards.sample}.unassembled.forward.fastq".format(wildcards=wildcards)),
                    os.path.join(RESULTDIR, "01-QualityControl", "merged", "{wildcards.sample}.unassembled.reverse.fastq".format(wildcards=wildcards)),
                    os.path.join(RESULTDIR, "01-QualityControl", "merged", "{wildcards.sample}.discarded.fastq".format(wildcards=wildcards)) ]
    elif MERGER == "bbmerge":
        return [    os.path.join(RESULTDIR, "01-QualityControl", "merged", "{wildcards.sample}_merged_fastq.gz".format(wildcards=wildcards)),
                    os.path.join(RESULTDIR, "01-QualityControl", "merged", "{wildcards.sample}_unmerged_fastq.gz".format(wildcards=wildcards))  ]
    elif MERGER == "none" and TRIM == "true":
        return [    os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{sample}_1.fastq.gz"),
                    os.path.join(RESULTDIR, "01-QualityControl", "trimmed_pe", "{sample}_2.fastq.gz"),
                    os.path.join(TEMPDIR, "TRIMMOMATIC", "untrimmed_pe", "{sample}_1.unpaired.fastq.gz"),
                    os.path.join(TEMPDIR, "TRIMMOMATIC", "untrimmed_pe", "{sample}_2.unpaired.fastq.gz")  ]
    else:
        return [    os.path.join(READDIR, "{wildcards.sample}_1".format(wildcards=wildcards), EXT),
                    os.path.join(READDIR, "{wildcards.sample}_2".format(wildcards=wildcards), EXT)   ]
