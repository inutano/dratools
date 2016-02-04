#!/bin/bash
#
# macs2_pipeline v0.1.0 by inutano@gmail.com
#
# usage:
#   ./macs2_pipeline.sh <Bowtie2 genome index directory> <GEO Sample ID or SRA Experiment ID of ChIP-Seq Experiment> <GEO Sample ID or SRA Experiment ID of Control Experiment> <working directory> <Control file KEEP or REMOVE>
#
set -eu

#
# functions
#

install_tools(){
  echo "=> Checking installed tools.."
}

retrieve_and_mapping(){
  local genome_index_dir=${1}
  local id=${2}
  local workdir=${3}
}

peak_calling(){
  local chipseq_bam=${1}
  local control_bam=${2}
}

#
# variables
#

bowtie2_index_dir=${1}
chipseq_identifier=${2}
control_identifier=${3}
working_dir=${4}
remove_control=${5}

#
# execute
#

# Install required tools
install_tools

# Mapping reads to reference genome by Bowtie2, generate two bam files
chipseq_bam=`retrieve_and_mapping "${bowtie2_index_dir}" "${chipseq_identifier}" "${working_dir}"`
control_bam=`retrieve_and_mapping "${bowtie2_index_dir}" "${control_identifier}" "${working_dir}"`

# peak calling by macs2 to generate narrowpeak data file
peak_calling "${chipseq_bam}" "${control_bam}"
