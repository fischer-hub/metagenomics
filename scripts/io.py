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

HELPMSG = f"""
{bcolors.HEADER}
help is on the way                                     
{bcolors.ENDC}
"""

# set static vars from config file here
READS           = config["reads"]
MODE            = config["mode"]
MERGER          = config["merger"] if MODE == "paired" else "none"
FASTQC          = config["fastqc"] 
RESULTDIR       = config["results"] if config["results"][-1] != '/' else config["results"][:-1]
CACHEDIR        = config["cache"] if config["cache"][-1] != '/' else config["cache"][:-1]
TEMPDIR         = config["temp"] if config["temp"][-1] != '/' else config["temp"][:-1]
CORETOOLS       = config["coretools"]
UNITS           = config["count_units"]
IDX_CHUNKS      = config["num_index_chunks"]
BLOCK_SIZE      = config["block_size"]
ADPT_PE         = config["adapters_pe"]
ADPT_SE         = config["adapters_se"]
MAX_MISMATCH    = config["max_mismatch"]
P_TH            = config["pThreshold"]
S_TH            = config["sThreshold"]
TRIM            = config["trim"]
REFERENCE       = config["reference"]