### WGS-Metagenomics
This is a `Snakemake` base pipeline for functional profiling of (WGS) metagenomic read data.
When finished, it is supposed to provide multiple modes to analyse the (relative) gene abundance and genetic profile of your samples and do some statistical analysis and visualisation on it as well.
As of right now the pipeline provides analysis via the tools:
- humann 
- carnelian (under construction)

A manual mode, mapping your reads against a reference to retrieve the gene counts is planned in the future.
Additionally optional automatic preprocessing of your read data (filtering and cleaning) is planned as well.

# Requirements
To run the pipeline you will need a working `Snakemake` installation as well as the `Anaconda` package manager on your machine. You can install Snakemake via `Anaconda` package manager as well.
To access your sample files the pipeline expects a csv file of the following format:

```
Sample,R1,R2
samplename,/path/to/sample/file/samplename_forward.ext,/path/to/sample/file/samplename_reverse.ext
samplename,/path/to/sample/file/samplename_forward.ext,/path/to/sample/file/samplename_reverse.ext
```

NOTE: If you have single-end reads put them in the `R1` column and leave `R2` empty. The pipeline will detect the read mode automatically and adjust accordingly.

# Installation
With `Snakemake` and `Anaconda` set up you can just clone and cd into this project via:
```
git clone https://github.com/fischer-hub/metagenomics && cd metagenomics
```
Start the pipeline with: 
```
snakemake --config reads=input.csv
```
On first run, the pipeline will download all necessary packages and install them into the according environments. This can take a while depending on your machine an internet connection.
After that the pipeline is independant of any network connection.

# Pipeline parameters
Additionally to the standard `Snakemake` parameters the pipeline comes with some custom ones that can be used after the `--config` flag:
```
cacheDir=           define the directory where the pipeline can store big files like databases and reference genomes [default: ./cacheDir]
resultDir=          define the directory where the pipeline can store result files [default: ./resultDir]
ext=                define the file extension of your read data [default: try to retrieve automatically]
protDB_build=       define the protein database build used for humann runs [default: uniref50_ec_filtered_diamond]
nucDB_build=        define the nucleotide translation database build used for humann runs [default: full]
```

NOTE: All of these parameters can be set permanently in the configuration file (profiles/config.yaml).

# Usage on high performance clusters (HPC)
The pipeline can be run on HPC's (only SLURM job manager supported right now) using the `--profile` flag eg.:
```
--profile profiles/allegro/
```
In this example the pipeline would run with specific settings for the `Allegro` high performance cluster of FU Berlin and manage your Snakemake rules as jobs (see more).
You can define your own HPC (or local) profiles and put them in the profiles dir to run as shown above. 
