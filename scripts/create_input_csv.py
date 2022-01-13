#!/usr/bin/env python3

import os
import sys
import glob
import argparse
from collections import defaultdict


def main(args=None):

    parser = argparse.ArgumentParser(description="Description of your program", epilog="Example usage: python3 create_input_csv.py <FASTQ_DIR>" )
    parser.add_argument("FASTQ_DIR", help="Description for foo argument")
    args = parser.parse_args()

    fastq_dir = args.FASTQ_DIR
    dictionary = defaultdict(list)
    WD = os.getcwd()

    files = sorted(glob.glob(os.path.join(fastq_dir, f"*.gz"), recursive=False))
    files = set(map(lambda x: (x.split("/")[-1].split("_")[0], x), files))

    for SRR, path in files:
        dictionary[SRR].append(path)
        dictionary[SRR].sort()
    
    with open('input.csv', 'w') as f:
        print("Sample,R1,R2", file=f)
        for SRR in dict(dictionary):
            print(f"{SRR.strip()},{WD + '/' + dict(dictionary)[SRR][0].strip()},{WD + '/' + dict(dictionary)[SRR][1].strip()}", file=f)

if __name__ == "__main__":
    sys.exit(main())