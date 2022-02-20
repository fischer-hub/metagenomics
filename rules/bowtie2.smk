def get_references(wildcards):
    file_paths = []
    for file in glob.glob(f"{REFERENCE}/*"):
        file_paths.append(file)
    return file_paths

rule bowtie2_index:
    input:  
        get_references
    output:
        one     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.1.bt2l"),
        two     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.2.bt2l"),
        three   = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.3.bt2l"),
        four    = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.4.bt2l"),
        rev_one = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.rev.1.bt2l"),
        rev_two = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.rev.2.bt2l")
    params:
        index_dir   = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1]),
        ref_dir     = REFERENCE
    log:
        os.path.join("log", "bowtie2", "bowtie2_index.log")
    conda:
        os.path.join("..", "envs", "bowtie2.yaml")
    threads:
        RES["bowtie2-index"]["cpu"]
    message:
        "bowtie2_index"
    resources:
        time = RES["bowtie2-index"]["time"]
    shell:
        """
        cat {input} > {params.ref_dir}_concat.fa 2> {log}
        mkdir -p {params.index_dir} 2>> {log}
        bowtie2-build --quiet --large-index --threads {threads} {params.ref_dir}_concat.fa {params.index_dir}/index 2>> {log}
        export BOWTIE2_INDEXES={params.index_dir} 2>> {log}
        rm {params.ref_dir}_concat.fa 2>> {log}
        """

def get_bowtie_reads(wildcards):
    if MODE == "paired":
        return os.path.join(RESULTDIR, "concat_reads", "{wildcards.sample}_concat.fq.gz".format(wildcards=wildcards))
    elif TRIM == "true":
        return os.path.join(RESULTDIR, "01-QualityControl", "trimmed_se", "{wildcards.sample}.fastq.gz".format(wildcards=wildcards))
    else:
        return os.path.join(READDIR, "{wildcards.sample}".format(wildcards=wildcards), EXT)

rule bowtie2_map:
    input:
        one     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.1.bt2l"),
        two     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.2.bt2l"),
        three   = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.3.bt2l"),
        four    = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.4.bt2l"),
        rev_one = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.rev.1.bt2l"),
        rev_two = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1], "index.rev.2.bt2l"),
        reads   = get_bowtie_reads
    output:
        unmapped = os.path.join(RESULTDIR, "bowtie2", "{sample}_unmapped.fastq.gz")
    params:
        ref_dir     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split("/")[-1]),
        file_format = FORMAT
    log:
        os.path.join("log", "bowtie2", "bowtie2_map_{sample}.log")
    conda:
        os.path.join("..", "envs", "bowtie2.yaml")
    threads:
        RES["bowtie2-map"]["cpu"]
    message:
        "bowtie2_map({wildcards.sample})"
    resources:
        time=lambda _, attempt: RES["bowtie2-map"]["time"] + ((attempt - 1) * RES["bowtie2-map"]["time"])
    shell:
        """
        bowtie2 --quiet {params.file_format} -x {params.ref_dir}/index -U {input.reads} --un-gz {output.unmapped} 2> {log} > /dev/null
        """
