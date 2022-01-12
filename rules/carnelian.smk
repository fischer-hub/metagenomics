rule carnelian_setup:
    output:
        "temp/flags/carnelian.install.done"
    shell: 
        """
        # download and set up carnelian
        mkdir -p bin && cd bin
        git clone https://github.com/snz20/carnelian.git && cd carnelian
        bash SETUP.sh && autopep8 -i carnelian.py
        """

rule carnelian_train:
    input: 
        "temp/flags/carnelian.install.done"
    output:
        model_dir = dir( config["resultDir"] + '/' + config["carnelian_model_dir"] )
    params:
        number_hash_fcts = config["carnelian_hash_fcts"] 
    shell:
        "carnelian train -k 8 --num_hash {params.number_hash_fcts} -l 30 -c 5 data/EC-2192-DB {output.model_dir}" 