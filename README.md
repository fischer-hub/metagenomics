# WGS-Metagenomics
This is a `Snakemake` based pipeline for functional profiling of (WGS) metagenomic read data.
When finished, it is supposed to provide multiple modes to analyse the (relative) gene abundance and genetic profile of your samples and do some statistical analysis and visualisation on it as well.
As of right now the pipeline provides analysis via the tools:
- [`HUMAnN 3.0`](https://github.com/biobakery/humann)
- [`MEGAN6`](https://uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/algorithms-in-bioinformatics/software/megan6/)
- [`carnelian`](https://github.com/snz20/carnelian) (under construction)

A manual mode, mapping your reads against a reference to retrieve the gene counts is planned in the future.
Additionally optional automatic preprocessing of your read data (filtering and cleaning) is planned as well.

## Requirements
To run the pipeline you will need a working [`Snakemake`](https://snakemake.readthedocs.io/en/stable/) installation as well as the [`Conda`](https://github.com/conda-forge/miniforge) package manager on your machine. A miniforge `Conda` installation is sufficient for this project:

```
wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh
bash Mambaforge-$(uname)-$(uname -m).sh
```
You can install and activate `Snakemake` via `Conda` package manager as well:

```
conda install -n base -c conda-forge mamba
conda activate base
mamba create -c conda-forge -c bioconda -n snakemake snakemake
conda activate snakemake
```
To access your sample files the pipeline expects a csv file of the following format:

```
Sample,R1,R2
samplename,/path/to/sample/file/samplename_forward.ext,/path/to/sample/file/samplename_reverse.ext
samplename,/path/to/sample/file/samplename_forward.ext,/path/to/sample/file/samplename_reverse.ext
```
NOTE: If you have single-end reads put them in the `R1` column and leave `R2` empty. The pipeline will detect the read mode automatically and adjust accordingly.

If your input files are all in the same directory you can use the `create_input_csv.py` script in `scripts/` to generate the `input.csv` file:
```
python3 scripts/create_input_csv.py <FASTQ_DIR>
```
## Installation
With `Snakemake` and `Conda` set up you can just clone and cd into this project via:
```
git clone https://github.com/fischer-hub/metagenomics && cd metagenomics
```
Start the pipeline locally with: 
```
snakemake --config reads=input.csv --profile profiles/local
```
Where `input.csv` is the csv file created before, providing information of your read data. On first run, the pipeline will download all necessary packages and install them into the according environments. This can take a while depending on your machine and internet connection.
After that the pipeline is independant of any network connection.

## Pipeline parameters
Additionally to the standard `Snakemake` parameters the pipeline comes with some custom ones that can be used after the `--config` flag.
### Required parameters
The following parameters are required to run the pipeline:
```
reads=                  comma seperated file that with information about the reads or dir that contains the reads [section Requirements](#requirements)
```
### Optional parameters

#### general
```
mode=               mode of the reads, only required if no samplesheet is provided [default: paired]
ext=                file extension of the read files, if not provided may be retrieved automatically [default: NULL]
help=               help flag, if set to true the help message is printed on start [default: false]
cleanup=            if set to true, temporary and intermediate files will be removed after a successful run [default: false]
```
#### directory structure
```
results= directory to store the results in [default: "./results"]
temp=               directory to store temporary and intermediate files in [default: "./temp"]
cache=              directory to store database and reference files in to use in multiple runs [default: "./cache"]
```
#### snakemake args
```
cores=              amount of cores the piepline is allowed to occupie, this also impacts how many jobs will run in parallel [default: 1]
use-conda=          if set to true, the pipeline will use the conda environment files to create environments for every rule to run in [default: true]
latency-wait=       amount of seconds the pipeline will wait for expected in- and output files to be present 
```
#### tools
```
fastqc=             if set to true, fastqc will be run during quality control steps, this should be false if input data is not in fastq format [default: true]
merger=             paired-end read merger to use [default: "bbmerge", "pear"]
coretools=          core tools to run [default: "humann,megan"]
trim=               if set to true, reads will be trimmed for adapter sequences before merging [default: true]
```
#### humann args
```
protDB_build=       protein database to use with HUMANN3.0 [default: "uniref50_ec_filtered_diamond"]
nucDB_build=        nucleotide database to use with HUMANN3.0 [default: "full"]
count_units=        unit to normalize HUMANN3.0 raw reads to [default: "cpm", "relab"]
```
NOTE: For alternative DBs please refer to the [HUMANN3.0 manual](https://github.com/biobakery/humann#databases) .

#### diamond args
```
block_size=         block size to use with diamond calls, higher block size increases memory usage and performance [default: 12]
num_index_chunks=   number of index chunks to use with diamond calls, lower number of index chunks increases memory usage and performance [default: 1]
```

#### bowtie2 args
```
reference=          reference genome file(s) to map against during decontamination of the reads, if no reference is provided decontamination is skipped [default: "none"]
```

#### trimmomatic args
```
adapters_pe=        file containing the adapters to trim for in paired-end runs [default: "assets/adapters/TruSeq3-PE.fa"]
adapters_se=        file containing the adapters to trim for in single-end runs [default: "assets/adapters/TruSeq3-SE.fa"]
max_mismatch=       max mismatch count to still allow for a full match to be performed [default: "2"]
pThreshold=         specifies how accurate the match between the two 'adapter ligated' reads must be for PE palindrome read alignment [default: "30"]
sThreshold:         specifies how accurate the match between any adapter etc. sequence must be against a read [default: "10"] 
min_adpt_len:       minimum adapter length in palindrome mode [default: "8"]
```

### differential gene abundance analysis args
```
metadata_csv=       CSV file containing metadata of the samples to analyse [default: "assets/test_data/metadata.csv"]
contrast_csv=       CSV file containing the contrasts to be taken into account [default: "assets/test_data/contrast.csv"]
formula=            R formatted model formula with variables to be taken into account [default: "cond+seed"]
plot_height=        height for plots to be generated [default: 11]
plot_width=         widht for plots to be generated [default: 11]
fc_th=              fold change threshold, drop all features with a fold change below this threshold [default: 1]
ab_th=              abundance threshold, drop all features with lower abundance than this threshold [default: 10]
pr_th=              prevalence threshold, drop all features with a prevalence below this threshold [default: 0.1]
sig_th=             significance threshold, drop all features with an adjusted p-value below this threshold [default: 1]
```

NOTE: All of these parameters can be set permanently in the configuration file (profiles/config.yaml).

## Usage on high performance clusters (HPC)
The pipeline can be run on HPC's (only SLURM job manager supported right now) using the `--profile` flag eg.:
```
--profile profiles/allegro/
```
In this example the pipeline would run with specific settings for the `Allegro` high performance cluster of FU Berlin and manage your Snakemake rules as jobs ([see more](https://github.com/Snakemake-Profiles/slurm)).
You can define your own HPC (or local) profiles and put them in the profiles dir to run as shown above. 

## Output
### Results
All important output files will be stored in the `results` directory, which you can find in the project directory of the pipeline if not defined otherwise in the pipeline call.
In said `results` directory you will find at most 5 sub directories:
```
00-Log
- this directory contains all the log files that have been created during the pipeline run
01-QualityControl
- this directory contains the fastqc reports, trimmed reads and merged paired-end reads
02-Decontamination
- this directory contains all the reads that didn't map to the reference genome (decontaminated reads)
03-CountData
- this directory contains the raw count data created by the core tools that were run (HUMANN3.0 and/or MEGAN6)
04-DifferentialGeneAbundance
- this directory contains results of the statistical analysis e.g. calculated log fold change and adjusted p-values per feature as well as plots for general- and per contrast data visualisation
05-Summary
- this directory contains summary data like reports for the pipeline run
```

## LICENSE

MIT License

Copyright (c) 2022 David Fischer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


