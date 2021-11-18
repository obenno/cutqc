#! /usr/bin/env bash

## Usage: Digest_fastqc

inputR1=$1;
shift 1;
inputR2=$1;
shift 1;
outHtml=$1;
shift 1;

read1_fileName=$(basename $inputR1)
read1_trimmed=${read1_fileName%%.f*q.gz}".trimmed.fq.gz"

read2_fileName=$(basename $inputR2)
read2_trimmed=${read2_fileName%%.f*q.gz}".trimmed.fq.gz"
##cutadapt_cmd=$(mktemp -p ./ cutadapt.XXXXXXXXXX)
cutadapt_cmd="cutadapt_command"
## conduct fastqc for origin reads
fastqc -t 2 --extract --nogroup -o ./ $inputR1 $inputR2
## cutadapt
echo "cutadapt $@ -o $read1_trimmed -p $read2_trimmed $inputR1 $inputR2" > $cutadapt_cmd
cutadapt $@ -o $read1_trimmed -p $read2_trimmed $inputR1 $inputR2
## conduct fastqc for trimmed reads
fastqc -t 2 --extract --nogroup -o ./ $read1_trimmed $read2_trimmed

fastqc_read1_before=${read1_fileName%%.f*q.gz}"_fastqc"
fastqc_read1_after=${read1_trimmed%%.f*q.gz}"_fastqc"
fastqc_read2_before=${read2_fileName%%.f*q.gz}"_fastqc"
fastqc_read2_after=${read2_trimmed%%.f*q.gz}"_fastqc"

read1_before_dir=$(mktemp -d -p ./ fastqc_read1_before.XXXXXXXXXX)
read1_after_dir=$(mktemp -d -p ./ fastqc_read1_after.XXXXXXXXXX)
read2_before_dir=$(mktemp -d -p ./ fastqc_read2_before.XXXXXXXXXX)
read2_after_dir=$(mktemp -d -p ./ fastqc_read2_after.XXXXXXXXXX)

## split read1_before
awk -F"\t" 'BEGIN{OFS="\t"}$1~/^>>/{outFileName=substr($1,3); gsub(" ", "_", outFileName);}$1!~/^>>/&&NR>1{if($1~/^#/){sub("#","",$1)}; print $0 >> "'$read1_before_dir/'"outFileName}' $fastqc_read1_before/fastqc_data.txt

## split read1_after
awk -F"\t" 'BEGIN{OFS="\t"}$1~/^>>/{outFileName=substr($1,3); gsub(" ", "_", outFileName);}$1!~/^>>/&&NR>1{if($1~/^#/){sub("#","",$1)}; print $0 >> "'$read1_after_dir/'"outFileName}' $fastqc_read1_after/fastqc_data.txt

## split read2_before
awk -F"\t" 'BEGIN{OFS="\t"}$1~/^>>/{outFileName=substr($1,3); gsub(" ", "_", outFileName);}$1!~/^>>/&&NR>1{if($1~/^#/){sub("#","",$1)}; print $0 >> "'$read2_before_dir/'"outFileName}' $fastqc_read2_before/fastqc_data.txt

## split read2_after
awk -F"\t" 'BEGIN{OFS="\t"}$1~/^>>/{outFileName=substr($1,3); gsub(" ", "_", outFileName);}$1!~/^>>/&&NR>1{if($1~/^#/){sub("#","",$1)}; print $0 >> "'$read2_after_dir/'"outFileName}' $fastqc_read2_after/fastqc_data.txt

## Generate html with Rmd
Rscript -e 'rmarkdown::render("fastqc_report.Rmd", params=list(read1_before_dir = "'$read1_before_dir'", read1_after_dir="'$read1_after_dir'", read2_before_dir = "'$read2_before_dir'", read2_after_dir = "'$read2_after_dir'"), knit_root_dir=getwd(), output_file="'$outHtml'")'

rm -rf $read1_before_dir $read1_after_dir $read2_before_dir $read2_after_dir
