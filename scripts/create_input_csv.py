#!/usr/bin/env python3

import os
import sys
import glob
import argparse
from collections import defaultdict


def main(args=None):

    parser = argparse.ArgumentParser(description="Description of your program", epilog="Example usage: python3 create_input_csv.py <FASTQ_DIR> <READ_MODE>" )
    parser.add_argument("FASTQ_DIR", help="Directory containing the fastq.gz files.")
    parser.add_argument("READ_MODE", help="Mode of the reads. Ommitting this can cause wrong sample names. [single, paired]")
    args = parser.parse_args()

    fastq_dir   = args.FASTQ_DIR
    mode        = args.READ_MODE
    dictionary = defaultdict(list)
    WD = os.getcwd()

    files = sorted(glob.glob(os.path.join(fastq_dir, f"*.gz"), recursive=False))
    files = set(map(lambda x: (x.split("/")[-1].rsplit(".")[0].rsplit("_")[0], x), files)) if mode != "single" else set(map(lambda x: (x.split("/")[-1].rsplit(".")[0], x), files))

    for SRR, path in files:
        dictionary[SRR].append(path)
        dictionary[SRR].sort()
    
    with open('input.csv', 'w') as f:
        print("Sample,R1,R2", file=f)
        for SRR in dict(dictionary):
            if len(dictionary[SRR]) < 2:
                print(f"{SRR.strip()},{dict(dictionary)[SRR][0].strip()},", file=f)

            else:
                print(f"{SRR.strip()},{dict(dictionary)[SRR][0].strip()},{dict(dictionary)[SRR][1].strip()}", file=f)




if __name__ == "__main__":
    sys.exit(main())