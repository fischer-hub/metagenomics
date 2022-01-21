rule pear:
    input:
        R1 = READDIR + "/{sample}_1" + EXT,
        R2 = READDIR + "/{sample}_2" + EXT
    output:
        assembled_pairs = config["resultDir"] + "/pear/{sample}.assembled.fastq",
        unassembled_fwd = config["resultDir"] + "/pear/{sample}.unassembled.forward.fastq",
        unassembled_rev = config["resultDir"] + "/pear/{sample}.unassembled.reverse.fastq",
        discarded_reads = config["resultDir"] + "/pear/{sample}.discarded.fastq"
    params:
        resultDir = config["resultDir"]
    log:
        "log/pear/{sample}_pear.log"
    conda:
        WD + "envs/pear.yaml"
    threads:
        8
    message:
        "pear({wildcards.sample})"
    resources:
        runtime=240
    shell:
        """
        mkdir -p {params.resultDir}/pear/
        pear -b 64 --threads {threads} --forward-fastq {input.R1} --reverse-fastq {input.R2} --output {params.resultDir}/pear/{wildcards.sample} > {log}
        #mv {wildcards.sample}.assembled.fastq {output.assembled_pairs} >> {log}
        #mv {wildcards.sample}.unassembled.forward.fastq {output.unassembled_fwd} >> {log}
        #mv {wildcards.sample}.unassembled.reverse.fastq {output.unassembled_rev} >> {log}
        #mv {wildcards.sample}.discarded.fastq {output.discarded_reads} >> {log}
        """