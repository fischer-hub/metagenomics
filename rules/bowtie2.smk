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
        "log/bowite2/bowtie2_index.log"
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
        bowtie2-build --large-index --threads {threads} {params.ref_dir}_concat.fa {params.index_dir}/index 2> {log}
        export BOWTIE2_INDEXES={params.index_dir} 2> {log}
        rm {params.ref_dir}_concat.fa 2> {log}
        """

rule bowtie2_map:
    input:
        one     = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.1.bt2l",
        two     = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.2.bt2l",
        three   = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.3.bt2l",
        four    = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.4.bt2l",
        rev_one = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.rev.1.bt2l",
        rev_two = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1] + "/index.rev.2.bt2l",
        reads   = config["resultDir"] + "/concat_reads/{sample}_concat.fq"
    output:
        unmapped = config["resultDir"] + "/bowtie2/{sample}_unmapped.fastq.gz"
    params:
        ref_dir  = config["cacheDir"] + "/bowtie2/" + config["bowtie2_reference"].split("/")[-1]
    log:
        "log/bowite2/bowtie2_map_{sample}.log"
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
        bowtie2 -x {params.ref_dir}/index -U {input.reads} --un-gz {output.unmapped} 2> {log}
        """
