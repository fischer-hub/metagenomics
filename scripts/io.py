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
{bcolors.ENDC}
"""

def path_check(path, is_file):
    if path[-1] == "/":
        path = path[0:-1]
    if exists(path):
        return path
    else:
        if is_file:
            print(f"{bcolors.FAIL}CRITICAL: File {path} does not exist, exiting..")
            exit()
        else:
            print(f"{bcolors.OKBLUE}INFO: Directory {path} does not exist, creating and hoping for the best now..")
            return path

# set static vars from config file here
READS           = path_check(config["reads"], True)
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
