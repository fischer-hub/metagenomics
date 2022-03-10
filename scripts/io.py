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
genes without jeans   |___ /                                       
{bcolors.ENDC}
"""
print(f"{BANNER}")

HELPMSG = f"""
{bcolors.HEADER}
help is on the way


### Required parameters
The following parameters are required to run the pipeline:
reads=                  comma seperated file that with information about the reads or dir that contains the reads [section Requirements](#requirements)

### Optional parameters

#### General
mode=               mode of the reads, only required if no samplesheet is provided [default: paired]
ext=                file extension of the read files, if not provided may be retrieved automatically [default: NULL]
help=               help flag, if set to true the help message is printed on start [default: false]
cleanup=            if set to true, temporary and intermediate files will be removed after a successful run [default: false]

#### Directory structure
results= directory to store the results in [default: "./results"]
temp=               directory to store temporary and intermediate files in [default: "./temp"]
cache=              directory to store database and reference files in to use in multiple runs [default: "./cache"]

#### Snakemake arguments
cores=              amount of cores the piepline is allowed to occupie, this also impacts how many jobs will run in parallel [default: 1]
use-conda=          if set to true, the pipeline will use the conda environment files to create environments for every rule to run in [default: true]
latency-wait=       amount of seconds the pipeline will wait for expected in- and output files to be present 

#### Tools
fastqc=             if set to true, fastqc will be run during quality control steps, this should be false if input data is not in fastq format [default: true]
merger=             paired-end read merger to use [default: "bbmerge", "pear"]
coretools=          core tools to run [default: "humann,megan"]
trim=               if set to true, reads will be trimmed for adapter sequences before merging [default: true]

#### HUMANN3.0 arguments
protDB_build=       protein database to use with HUMANN3.0 [default: "uniref50_ec_filtered_diamond"]
nucDB_build=        nucleotide database to use with HUMANN3.0 [default: "full"]
count_units=        unit to normalize HUMANN3.0 raw reads to [default: "cpm", "relab"]
NOTE: For alternative DBs please refer to the [HUMANN3.0 manual](https://github.com/biobakery/humann#databases) .

#### DIAMOND arguments
block_size=         block size to use with diamond calls, higher block size increases memory usage and performance [default: 12]
num_index_chunks=   number of index chunks to use with diamond calls, lower number of index chunks increases memory usage and performance [default: 1]

#### Bowtie2 arguments
reference=          reference genome file(s) to map against during decontamination of the reads, if no reference is provided decontamination is skipped [default: "none"]

#### TRIMMOMATIC arguments
adapters_pe=        file containing the adapters to trim for in paired-end runs [default: "assets/adapters/TruSeq3-PE.fa"]
adapters_se=        file containing the adapters to trim for in single-end runs [default: "assets/adapters/TruSeq3-SE.fa"]
max_mismatch=       max mismatch count to still allow for a full match to be performed [default: "2"]
pThreshold=         specifies how accurate the match between the two 'adapter ligated' reads must be for PE palindrome read alignment [default: "30"]
sThreshold:         specifies how accurate the match between any adapter etc. sequence must be against a read [default: "10"] 
min_adpt_len:       minimum adapter length in palindrome mode [default: "8"]

### Statistical analysis arguments
metadata_csv=       CSV file containing metadata of the samples to analyse [default: "assets/test_data/metadata.csv"]
contrast_csv=       CSV file containing the contrasts to be taken into account [default: "assets/test_data/contrast.csv"]
formula=            R formatted model formula with variables to be taken into account [default: "cond+seed"]
plot_height=        height for plots to be generated [default: 11]
plot_width=         widht for plots to be generated [default: 11]
fc_th=              fold change threshold, drop all features with a fold change below this threshold [default: 1]
ab_th=              abundance threshold, drop all features with lower abundance than this threshold [default: 10]
pr_th=              prevalence threshold, drop all features with a prevalence below this threshold [default: 0.1]
sig_th=             significance threshold, drop all features with an adjusted p-value below this threshold [default: 1]
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
REFERENCE       = path_check(config["reference"], True)
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