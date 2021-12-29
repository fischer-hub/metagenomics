rule carnelian_setup:
    output:
        "temp/flags/sequtil.done",
        "temp/flags/ldpc.done",
        "temp/flags/Bio.done"
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
        model_dir = dir( config["resultDir"] + '/' + config["carnelian_model_dir"] )
    params:
        number_hash_fcts = config["carnelian_hash_fcts"] 
    shell:
        "carnelian train -k 8 --num_hash {params.number_hash_fcts} -l 30 -c 5 data/EC-2192-DB {output.model_dir}" 