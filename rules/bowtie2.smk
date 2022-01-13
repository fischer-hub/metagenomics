#align
#bowtie2 -x example/index/lambda_virus -1 example/reads/reads_1.fq -2 example/reads/reads_2.fq

# Building a small index
#bowtie2-build example/reference/lambda_virus.fa example/index/lambda_virus

# Building a large index
#bowtie2-build --large-index example/reference/lambda_virus.fa example/index/lambda_virus

rule bowtie2_index:
    output:
        one     = config["cacheDir"] + "bowtie2/" + config["bowtie2_reference"] + "/index.1.bt2l",
        two     = config["cacheDir"] + "bowtie2/" + config["bowtie2_reference"] + "/index.2.bt2l",
        three   = config["cacheDir"] + "bowtie2/" + config["bowtie2_reference"] + "/index.3.bt2l",
        four    = config["cacheDir"] + "bowtie2/" + config["bowtie2_reference"] + "/index.4.bt2l",
        rev_one = config["cacheDir"] + "bowtie2/" + config["bowtie2_reference"] + "/index.rev.1.bt2l",
        rev_two = config["cacheDir"] + "bowtie2/" + config["bowtie2_reference"] + "/index.rev.2.bt2l"
    params:
        reference       = config["bowtie2_reference"],
        index_dir       = config["cacheDir"] + "bowtie2/index/" + config["bowtie2_reference"],
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
        bowtie2-build --large-index --threads {threads} {params.reference} index
        mv *.bt2l {params.index_dir}
        """