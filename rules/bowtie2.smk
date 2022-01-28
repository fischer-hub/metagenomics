def get_references(wildcards):
    file_paths = []
    for file in glob.glob(config["bowtie2_reference"] + "/*"):
        file_paths.append(file)
    return file_paths

rule bowtie2_index:
    input:  
        get_references
    output:
        one     = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.1.bt2l",
        two     = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.2.bt2l",
        three   = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.3.bt2l",
        four    = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.4.bt2l",
        rev_one = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.rev.1.bt2l",
        rev_two = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.rev.2.bt2l"
    params:
        index_dir   = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1],
        ref_dir     = config["bowtie2_reference"]
    log:
        "log/bowtie2/bowtie2_index.log"
    conda:
        WD + "envs/bowtie2.yaml"
    threads:
        16
    message:
        "bowtie2_index"
    resources:
        runtime=240
    shell:
        """
        cat {input} > {params.ref_dir}_concat.fa 2> {log}
        mkdir -p {params.index_dir} 2>> {log}
        bowtie2-build --large-index --threads {threads} {params.ref_dir}_concat.fa {params.index_dir}/index 2>> {log}
        export BOWTIE2_INDEXES={params.index_dir} 2>> {log}
        rm {params.ref_dir}_concat.fa 2>> {log}
        """

def get_bowtie_reads(wildcards):
    if param_mode == "paired":
        return RESULTDIR + "/concat_reads/{wildcards.sample}_concat.fq".format(wildcards=wildcards)
    elif config["qc"] == "true":
        return RESULTDIR + "/01-QualityControl/trimmed_se/{wildcards.sample}.fastq.gz".format(wildcards=wildcards)
    else:
        return READDIR + "/{wildcards.sample}".format(wildcards=wildcards) + EXT

rule bowtie2_map:
    input:
        one     = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.1.bt2l",
        two     = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.2.bt2l",
        three   = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.3.bt2l",
        four    = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.4.bt2l",
        rev_one = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.rev.1.bt2l",
        rev_two = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.rev.2.bt2l",
        reads   = get_bowtie_reads
    output:
        unmapped = config["resultDir"] + "/bowtie2/{sample}_unmapped.fastq.gz"
    params:
        ref_dir     = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1],
        file_format = FORMAT
    log:
        "log/bowtie2/bowtie2_map_{sample}.log"
    conda:
        WD + "envs/bowtie2.yaml"
    threads:
        16
    message:
        "bowtie2_map({wildcards.sample})"
    resources:
        runtime=480
    shell:
        """
        bowtie2 {params.file_format} -x {params.ref_dir}/index -U {input.reads} --un-gz {output.unmapped} 2> {log}
        """
