# WGS-Metagenomics
This is a `Snakemake` base pipeline for functional profiling of (WGS) metagenomic read data.
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
Start the pipeline with: 
```
snakemake --config reads=input.csv
```
Where `input.csv` is the csv file created before, providing information of your read data. On first run, the pipeline will download all necessary packages and install them into the according environments. This can take a while depending on your machine an internet connection.
After that the pipeline is independant of any network connection.

## Pipeline parameters
Additionally to the standard `Snakemake` parameters the pipeline comes with some custom ones that can be used after the `--config` flag:
```
cacheDir=               define the directory where the pipeline can store big files like databases and reference genomes [default: ./cacheDir]
resultDir=              define the directory where the pipeline can store result files [default: ./resultDir]
ext=                    define the file extension of your read data [default: try to retrieve automatically]
protDB_build=           define the protein database build used for humann runs [default: uniref50_ec_filtered_diamond]
nucDB_build=            define the nucleotide translation database build used for humann runs [default: full]
humann_count_units=     define units for gene counts [cpm (counts per million), relab (relative abundance), default: cpm]
dmnd_block_size=        block size to run `DIAMOND`, mem. usage is approximately 6 times this value, increases performance for increased values
dmnd_num_index_chunks=  number of index chunks to run `DIAMOND` on, lower values increase the performance
```
These can be useful when runnin in environments where the project directory is storage limited and one might want to have large files in other directories without storage limits (this could be the case on shared machines like HPC's where you would want big temporary files on lets say /scratch or similar).\
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
As of right now the pipeline will output combined gene abundance tables in `resultDir/humann/`. Here you can aso find the individual gene abundance tables for every sample, normalized for gene length and amount of reads per sample (relative abundances) and raw (absoulte abundance).

### Logs
All log files are saved to `log/$toolname` and contain the standard output of the tool.\
NOTE: On HPCs the job manager might catch the stdout before going to the log files resulting in empty logs. You can find the stdout of each job in its job-log file. For `SLURM` these will be redirected to the `slurm/` directory of the project dir.




