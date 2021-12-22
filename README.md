# Cutqc

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](http://bioconda.github.io/recipes/cutqc/README.html)
[![](https://img.shields.io/conda/dn/bioconda/cutqc.svg?style=flat)](https://anaconda.org/bioconda/cutqc)

`cutqc.sh` is a wrapper to perform cutadapt and fastqc, and generate
an aggregated report for pair-end reads, empowered by rmarkdown and plotly.

```bash
$ cutqc.sh -h
cutqc.sh <cutqc> in_read1.fq.gz in_read2.fq.gz out_report.html [cutadapt_option]

cutqc.sh <qc_only> in_read.fq.gz [output_report.html]

cutqc has two valid subcommands:
    cutqc:
        Take pair-end inputs (R1.fq.gz and R2.fq.gz) and perform cutadapt in pair-end mode.
        Fastqc will be performed both before and after trimming. The first three arguments
        are mandatory and positional, all the following options will be parsed to cutadapt,
        please refer to cutadapt manual for full option list.

    qc_only:
        Take one single fastq file as input and perfom fastqc only.

Please note only gzipped input file(s) are supported.
```

## Install

```
conda install -c bioconda cutqc
```

## Cutqc Report

![](/images/cutqc_report.gif)
