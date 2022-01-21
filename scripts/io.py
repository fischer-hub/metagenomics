import argparse

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


parser = argparse.ArgumentParser(description="This is a Snakemake workflow for the functional analysis of metagenomic WGS read data.", epilog="Example usage: snakemake --config reads=<INPUT_CSV>" )
parser.add_argument("FASTQ_DIR", help="Description for foo argument")
args, unknown = parser.parse_known_args()

