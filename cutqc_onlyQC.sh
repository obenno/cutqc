#! /usr/bin/env bash

set -eo pipefail

## Usage:
usage="cutqc_onlyQC.sh in_read.fq.gz [out_report.html]

PLEASE REFER TO FASTQC MANUAL ALSO.

This onlyQC program will only perform fastqc on input
reads and generate cutqc style fastqc report (html).

Only gzipped input files are supported.
Please note the arguments are positional.
"

if [[ -z $1 || $1 == "-h" || $1 == "-help" ]]; then
    echo -e "$usage";
    exit 0;
fi;

inputRead=$1;
shift 1;
outHtml=$1;
shift 1;

if [[ -z $outHtml ]]
then
    outHtml=${inputRead%%.f*q.gz}".fastqc_report.html"
fi

read_fileName=$(basename $inputRead)
## conduct fastqc for origin reads
fastqc -t 2 --extract --nogroup -o ./ $inputRead

fastqc_out=${read_fileName%%.f*q.gz}"_fastqc"

read_tmp_dir=$(mktemp -d -p ./ fastqc_read1_before.XXXXXXXXXX)

## split fastqc output
awk -F"\t" 'BEGIN{OFS="\t"}$1~/^>>/{outFileName=substr($1,3); gsub(" ", "_", outFileName);}$1!~/^>>/&&NR>1{if($1~/^#/){sub("#","",$1)}; print $0 >> "'$read_tmp_dir/'"outFileName}' $fastqc_out/fastqc_data.txt

## Generate html with Rmd
Rscript -e 'rmarkdown::render("fastqc_single_report.Rmd", params=list(read_fastqc_dir = "'$read_tmp_dir'"), intermediates_dir=getwd(), knit_root_dir=getwd(), output_dir = getwd(), output_file="'$outHtml'")'

rm -rf $read_tmp_dir
