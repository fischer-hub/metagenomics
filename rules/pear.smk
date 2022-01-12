rule daa_meganize:
    input:
        R1 = READDIR + "/{sample}_1" + EXT,
        R2 = READDIR + "/{sample}_2" + EXT
    output:
    params:
    log:
        "log/pear/{sample}_pear.log"
    conda:
        WD + "envs/pear.yaml"
    threads:
        16
    message:
        "pear({wildcards.sample})"
    resources:
        runtime=960
    shell:
        """
        ./pear -f {input.R1} -r {input.R2} -o {output}
        """