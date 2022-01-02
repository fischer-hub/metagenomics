rule carnelian_setup:
    output:
        seutil_flag = "temp/flags/sequtil.done",
        ldpc_flag = "temp/flags/ldpc.done",
        bio_flag = "temp/flags/Bio.done"
    log:
        "log/carnelian/setup.log"
    message:
        "carnelian_setup()"
    threads:
        1
    shell: 
        """
        # download and set up carnelian
        mkdir -p bin && cd bin
        git clone https://github.com/snz20/carnelian.git && cd carnelian
        bash SETUP.sh && autopep8 -i carnelian.py

        # install required python modules
        pip install sequtil && touch sequtil.done
        pip install ldpc && touch ldpc.done
        pip install Bio && touch Bio.done
        """

rule carnelian_train:
    input: 
        "temp/flags/sequtil.done",
        "temp/flags/ldpc.done",
        "temp/flags/Bio.done"
    output:
        touch("temp/flags/carnelian.train")
        model_dir = directory( config["resultDir"] + '/' + config["carnelian_model_dir"] )
    params:
        number_hash_fcts = config["carnelian_hash_fcts"]
    log:
        "log/carnelian/train.log"
    message:
        "carnelian_train()"
    threads:
        1
    shell:
        "python bin/carnelian/carnelian.py train -k 8 --num_hash {params.number_hash_fcts} -l 30 -c 5 data/EC-2192-DB {output.model_dir}" 

rule carnelian_annotate:
    input:
        fasta = config["resultDir"] + "/merged_pairs/{sample}_merged.fq" + EXT
    output:
        outdir = directory( config["resultDir"] + "/carnelian/annotated/" )
    params:
        model_dir = directory( config["resultDir"] + '/' + config["carnelian_model_dir"] )
    threads:
        16
    log:
        "log/carnelian/annotate/{sample}.log"
    message:
        "carnelian_annotate({wildcards.sample})"
    shell: 
        "python bin/carnelian/carnelian.py annotate -k 8 -n {threads} {input.fasta} {params.model_dir} {output.outdir} "


rule carnelian_abundance:
    input:
        expand( config["resultDir"] + "/carnelian/annotated/", sample = SAMPLE )
    output:
        outdir = directory( config["resultDir"] + "/carnelian/annotated/" )
    params:
        model_dir = directory( config["resultDir"] + '/' + config["carnelian_model_dir"] )
    threads:
        16
    log:
        "log/carnelian/annotate/{sample}.log"
    message:
        "carnelian_annotate({wildcards.sample})"
    shell: 
        "python bin/carnelian/carnelian.py abundance <labels_dir> <abundance_matrix_dir> <sampleinfo_file> data/EC-2192-DB/ec_info.tsv"