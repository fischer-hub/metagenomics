rule bowtie2_index:
    input:  
        get_references
    output:
        one     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.1.bt2l"),
        two     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.2.bt2l"),
        three   = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.3.bt2l"),
        four    = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.4.bt2l"),
        rev_one = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.rev.1.bt2l"),
        rev_two = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.rev.2.bt2l")
    params:
        index_dir   = lambda w, output: os.path.split(output[0])[0], #os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1]),
        ref_dir     = REFERENCE
    log:
        os.path.join(RESULTDIR, "00-Log", "bowtie2", "bowtie2_index.log")
    conda:
        os.path.join("..", "envs", "bowtie2.yaml")
    resources:
        time        = RES["bowtie2_index"]["time"],
        mem_mb      = RES["bowtie2_index"]["mem"] * 1024,
        partition   = RES["bowtie2_index"]["partition"]
    threads:
        RES["bowtie2_index"]["cpu"]
    message:
        "bowtie2_index\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    shell:
        """
        cat {input} > {params.ref_dir}_concat.fa 2> {log}
        mkdir -p {params.index_dir} 2>> {log}
        bowtie2-build --quiet --large-index --threads {threads} {params.ref_dir}_concat.fa {params.index_dir}/index 2>> {log}
        export BOWTIE2_INDEXES={params.index_dir} 2>> {log}
        rm {params.ref_dir}_concat.fa 2>> {log}
        """


rule bowtie2_map:
    input:
        one     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.1.bt2l"),
        two     = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.2.bt2l"),
        three   = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.3.bt2l"),
        four    = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.4.bt2l"),
        rev_one = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.rev.1.bt2l"),
        rev_two = os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1], "index.rev.2.bt2l"),
        reads   = get_bowtie_reads
    output:
        unmapped = os.path.join(RESULTDIR, "02-Decontamination", "{sample}_unmapped.fastq.gz")
    params:
        ref_dir     = lambda w, input: os.path.split(input[0])[0], #os.path.join(CACHEDIR, "bowtie2", REFERENCE.split(os.path.sep)[-1]),
        file_format = FORMAT
    log:
        os.path.join(RESULTDIR, "00-Log", "bowtie2", "bowtie2_map_{sample}.log")
    conda:
        os.path.join("..", "envs", "bowtie2.yaml")
    message:
        "bowtie2_map({wildcards.sample})\ncpu: {threads}, mem: {resources.mem_mb}, time: {resources.time}, part: {resources.partition}"
    resources:
        time        = lambda _, attempt: RES["bowtie2_map"]["time"] + ((attempt - 1) * RES["bowtie2_map"]["time"]),
        mem_mb      = RES["bowtie2_map"]["mem"] * 1024,
        partition   = RES["bowtie2_map"]["partition"]
    threads:
        RES["bowtie2_map"]["cpu"]
    shell:
        """
        bowtie2 --quiet {params.file_format} -x {params.ref_dir}/index -U {input.reads} --un-gz {output.unmapped} 2> {log} > /dev/null
        """
