#! /usr/bin/env bash

set -eo pipefail

## Usage:
usage="
cutqc.sh <cutqc> in_read1.fq.gz in_read2.fq.gz out_report.html [cutadapt_option]

cutqc.sh <qc_only> in_read.fq.gz [output_report.html]

cutqc has two valid subcommands:
    cutqc:
        Take pair-end inputs (R1.fq.gz and R2.fq.gz) and perform cutadapt in pair-end mode.
        Fastqc will be performed both before and after trimming. The first three arguments
        are mandatory and positional, all the following options will be parsed to cutadapt,
        please refer to cutadapt manual for full option list. Please also don't pass -o and
        -p argument to cutadapt.

    qc_only:
        Take one single fastq file as input and perfom fastqc only.

Please note only gzipped input file(s) are supported.
"

usage(){
    echo -e "$usage";
    exit 0;
}

sub_cutqc(){
    if [[ -z $1 || $1 == "-h" || $1 == "-help" ]]; then
        echo -e "$usage";
        exit 0;
    fi;

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
    Rscript -e 'rmarkdown::render("fastqc_report.Rmd", params=list(read1_before_dir = "'$read1_before_dir'", read1_after_dir="'$read1_after_dir'", read2_before_dir = "'$read2_before_dir'", read2_after_dir = "'$read2_after_dir'"), intermediates_dir=getwd(), knit_root_dir=getwd(), output_dir = getwd(), output_file="'$outHtml'")'

    rm -rf $read1_before_dir $read1_after_dir $read2_before_dir $read2_after_dir
    rm -rf *_fastqc
}

sub_qc_only(){
    if [[ -z $1 || $1 == "-h" || $1 == "-help" ]]; then
        echo -e "$usage";
        exit 0;
    fi;

    inputRead=$1;
    shift 1;

    if [[ -z $1 ]]
    then
        outHtml=${inputRead%%.f*q.gz}".fastqc_report.html"
    else
        outHtml=$1;
        shift 1;
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
    rm -rf *_fastqc
}

if [[ -z $1 ]]
then
    subcommand=""
else
    subcommand=$1
    shift 1;
fi

case $subcommand in
    "" | "-h" | "--help")
        usage
        ;;
    "cutqc")
        sub_cutqc $@
        ;;
    "qc_only")
        sub_qc_only $@
        ;;
    *)
        echo "Please provide valid subcommand: cutqc or qc_only"
        exit 1
esac
