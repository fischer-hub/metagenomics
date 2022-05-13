from genericpath import exists


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARN = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

BANNER = f"""
{bcolors.HEADER}
 __  __      _                                         _          
|  \/  |    | |                                       (_)         
| \  / | ___| |_ __ _  __ _  ___ _ __   ___  _ __ ___  _  ___ ___ 
| |\/| |/ _ \ __/ _` |/ _` |/ _ \ '_ \ / _ \| '_ ` _ \| |/ __/ __|
| |  | |  __/ || (_| | (_| |  __/ | | | (_) | | | | | | | (__\__ \\
|_|  |_|\___|\__\__,_|\__, |\___|_| |_|\___/|_| |_| |_|_|\___|___/
                       __/ |                                      
genes without jeans   |___ /                         version 1.0.0  
{bcolors.ENDC}
"""
print(f"{BANNER}")

HELPMSG = f"""
{bcolors.OKBLUE}usage: snakemake --config reads=input.csv metadata_csv=meta.csv contrast_csv=contr.csv formula=cond ... [custom parameters] ... --profile profiles/local/ {bcolors.ENDC}

{bcolors.WARN}### Required parameters{bcolors.ENDC}
{bcolors.OKGREEN}reads=              {bcolors.ENDC}comma seperated file that with information about the reads or dir that contains the reads [section Requirements](#requirements)

{bcolors.WARN}### Optional parameters{bcolors.ENDC}

{bcolors.WARN}#### General{bcolors.ENDC}
{bcolors.OKGREEN}mode=               {bcolors.ENDC}mode of the reads, only required if no samplesheet is provided [default: paired]
{bcolors.OKGREEN}ext=                {bcolors.ENDC}file extension of the read files, if not provided may be retrieved automatically [default: NULL]
{bcolors.OKGREEN}help=               {bcolors.ENDC}help flag, if set to true the help message is printed on start [default: false]
{bcolors.OKGREEN}cleanup=            {bcolors.ENDC}if set to true, temporary and intermediate files will be removed after a successful run [default: false]

{bcolors.WARN}#### Directory structure{bcolors.ENDC}
{bcolors.OKGREEN}results= directory t{bcolors.ENDC}o store the results in [default: "./results"]
{bcolors.OKGREEN}temp=               {bcolors.ENDC}directory to store temporary and intermediate files in [default: "./temp"]
{bcolors.OKGREEN}cache=              {bcolors.ENDC}directory to store database and reference files in to use in multiple runs [default: "./cache"]

{bcolors.WARN}#### Snakemake arguments{bcolors.ENDC}
{bcolors.OKGREEN}cores=              {bcolors.ENDC}amount of cores the piepline is allowed to occupie, this also impacts how many jobs will run in parallel [default: 1]
{bcolors.OKGREEN}use-conda=          {bcolors.ENDC}if set to true, the pipeline will use the conda environment files to create environments for every rule to run in [default: true]
{bcolors.OKGREEN}latency-wait=       {bcolors.ENDC}amount of seconds the pipeline will wait for expected in- and output files to be present 

{bcolors.WARN}#### Tools{bcolors.ENDC}
{bcolors.OKGREEN}fastqc=             {bcolors.ENDC}if set to true, fastqc will be run during quality control steps, this should be false if input data is not in fastq format [default: true]
{bcolors.OKGREEN}merger=             {bcolors.ENDC}paired-end read merger to use [default: "bbmerge", "pear"]
{bcolors.OKGREEN}coretools=          {bcolors.ENDC}core tools to run [default: "humann,megan"]
{bcolors.OKGREEN}trim=               {bcolors.ENDC}if set to true, reads will be trimmed for adapter sequences before merging [default: true]

{bcolors.WARN}#### HUMANN3.0 arguments{bcolors.ENDC}
{bcolors.OKGREEN}protDB_build=       {bcolors.ENDC}protein database to use with HUMANN3.0 [default: "uniref50_ec_filtered_diamond"]
{bcolors.OKGREEN}nucDB_build=        {bcolors.ENDC}nucleotide database to use with HUMANN3.0 [default: "full"]
{bcolors.OKGREEN}count_units=        {bcolors.ENDC}unit to normalize HUMANN3.0 raw reads to [default: "cpm", "relab"]
                    NOTE: For alternative DBs please refer to the [HUMANN3.0 manual](https://github.com/biobakery/humann#databases) .

{bcolors.WARN}#### DIAMOND arguments{bcolors.ENDC}
{bcolors.OKGREEN}block_size=         {bcolors.ENDC}block size to use with diamond calls, higher block size increases memory usage and performance [default: 12]
{bcolors.OKGREEN}num_index_chunks=   {bcolors.ENDC}number of index chunks to use with diamond calls, lower number of index chunks increases memory usage and performance [default: 1]

{bcolors.WARN}#### Bowtie2 arguments{bcolors.ENDC}
{bcolors.OKGREEN}reference=          {bcolors.ENDC}reference genome file(s) to map against during decontamination of the reads, if no reference is provided decontamination is skipped [default: "none"]

{bcolors.WARN}#### TRIMMOMATIC arguments{bcolors.ENDC}
{bcolors.OKGREEN}adapters_pe=        {bcolors.ENDC}file containing the adapters to trim for in paired-end runs [default: "assets/adapters/TruSeq3-PE.fa"]
{bcolors.OKGREEN}adapters_se=        {bcolors.ENDC}file containing the adapters to trim for in single-end runs [default: "assets/adapters/TruSeq3-SE.fa"]
{bcolors.OKGREEN}max_mismatch=       {bcolors.ENDC}max mismatch count to still allow for a full match to be performed [default: "2"]
{bcolors.OKGREEN}pThreshold=         {bcolors.ENDC}specifies how accurate the match between the two 'adapter ligated' reads must be for PE palindrome read alignment [default: "30"]
{bcolors.OKGREEN}sThreshold:         {bcolors.ENDC}specifies how accurate the match between any adapter etc. sequence must be against a read [default: "10"] 
{bcolors.OKGREEN}min_adpt_len:       {bcolors.ENDC}minimum adapter length in palindrome mode [default: "8"]

{bcolors.WARN}### Statistical analysis arguments{bcolors.ENDC}
{bcolors.OKGREEN}metadata_csv=       {bcolors.ENDC}CSV file containing metadata of the samples to analyse [default: "assets/test_data/metadata.csv"]
{bcolors.OKGREEN}contrast_csv=       {bcolors.ENDC}CSV file containing the contrasts to be taken into account [default: "assets/test_data/contrast.csv"]
{bcolors.OKGREEN}formula=            {bcolors.ENDC}R formatted model formula with variables to be taken into account [default: "cond+seed"]
{bcolors.OKGREEN}plot_height=        {bcolors.ENDC}height for plots to be generated [default: 11]
{bcolors.OKGREEN}plot_width=         {bcolors.ENDC}widht for plots to be generated [default: 11]
{bcolors.OKGREEN}fc_th=              {bcolors.ENDC}fold change threshold, drop all features with a fold change below this threshold [default: 1]
{bcolors.OKGREEN}ab_th=              {bcolors.ENDC}abundance threshold, drop all features with lower abundance than this threshold [default: 10]
{bcolors.OKGREEN}pr_th=              {bcolors.ENDC}prevalence threshold, drop all features with a prevalence below this threshold [default: 0.1]
{bcolors.OKGREEN}sig_th=             {bcolors.ENDC}significance threshold, drop all features with an adjusted p-value below this threshold [default: 1]
{bcolors.ENDC}
"""

def path_check(path, is_file):
    if path and path[-1] == "/":
        path = path[0:-1]
    if exists(path):
        return path
    else:
        if is_file:
            print(f"{bcolors.FAIL}CRITICAL: File {path} does not exist, exiting if this is an essential file..")
            return ""
        else:
            print(f"{bcolors.OKBLUE}INFO: Directory {path} does not exist, creating and hoping for the best now..")
            os.makedirs(path, exist_ok=True)
            return path

# set static vars from config file here
READS           = config["reads"] if path_check(config["reads"], True) else quit()
MODE            = config["mode"]
MERGER          = config["merger"] if MODE == "paired" else "none"
FASTQC          = config["fastqc"] 
RESULTDIR       = path_check(config["results"], False)
CACHEDIR        = path_check(config["cache"], False)
TEMPDIR         = path_check(config["temp"], False)
CORETOOLS       = config["coretools"]
UNITS           = config["count_units"]
IDX_CHUNKS      = config["num_index_chunks"]
BLOCK_SIZE      = config["block_size"]
ADPT_PE         = config["adapters_pe"]
ADPT_SE         = config["adapters_se"]
MAX_MISMATCH    = config["max_mismatch"]
MIN_ADPT_LEN    = config["min_adpt_len"]
P_TH            = config["pThreshold"]
S_TH            = config["sThreshold"]
TRIM            = config["trim"]
REFERENCE       = path_check(config["reference"], False)
WORK_DIR        = os.getcwd()
FORMULA         = config["formula"]
HEIGHT          = config["plot_height"]
WIDTH           = config["plot_width"]
FC_TH           = config["fc_th"]
AB_TH           = config["ab_th"]
PR_TH           = config["pr_th"]
SIG_TH          = config["sig_th"]
META            = path_check(config["metadata_csv"], True)
CONTRAST        = path_check(config["contrast_csv"], True)
CLEAN           = config["cleanup"]
ID_TH           = config["id_th"]
TOP_RANGE       = config["top_range"]

with open('profiles/resource.yaml', 'r') as f:
    RES = yaml.load(f, Loader=yaml.FullLoader)
