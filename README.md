[![Anaconda-Server Badge](https://anaconda.org/bioconda/cutqc/badges/installer/conda.svg)](https://conda.anaconda.org/bioconda)

`cutqc.sh` is a wrapper to perform cutadapt and fastqc, and generate
an aggregated report for pair-end reads, empowered by rmarkdown and plotly.

```bash
$ cutqc.sh -h
cutqc.sh in_read1.fq.gz in_read2.fq.gz out_report.html [cutadapt_option]

PLEASE REFER TO CUTADAPT AND FASTQC MANUAL ALSO.

Only pair-end gzipped input files are supported.

The first three arguments are mandatory and positional, all the other options
followed will be parsed to cutadapt, please refer to cutadapt manual.
```

## Install

```
conda install -c bioconda cutqc
```
