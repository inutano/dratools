#!/bin/bash
#
# bowtie2_pipeline v0.1.0 by inutano@gmail.com
#
# usage:
#   ./bowtie2_pipeline.sh <Bowtie2 genome index dir> <GEO Sample or SRA Experiment ID> <output dir>
#
set -eu

#
# functions
#

## installing required tools

install_tools(){
  install_bowtie2
  install_samtools
}

bowtie2_version(){
  # specify bowtie2 version here
  echo "2.2.6"
}

samtools_version(){
  # specify samtools version here
  echo "1.3"
}

install_bowtie2(){
  # setup install directory
  local dra_dir="/home/`id -nu`/.dra"
  local bin_dir="${dra_dir}/bin"
  local src_dir="${dra_dir}/src"
  mkdir -p "${bin_dir}"
  mkdir -p "${src_dir}"

  # download bowtie2 binary
  local version=`bowtie2_version`
  local url_base="http://sourceforge.net/projects/bowtie-bio/files/bowtie2"
  local fname="bowtie2-${version}-linux-x86_64.zip"
  wget -O "${src_dir}/${fname}" "${url_base}/${version}/${url_file}"

  # unzip and create symlinks
  cd "${src_dir}" && unzip "${fname}"
  ls "${src_dir}/${fname%-linux-x86_64.zip}/" | grep "bowtie" | xargs -i ln -s "${src_dir}/${fname%-linux-x86_64.zip}/"{} "${bin_dir}"
}

install_samtools(){
  # setup install directory
  local dra_dir="/home/`id -nu`/.dra"
  local bin_dir="${dra_dir}/bin"
  local src_dir="${dra_dir}/src"
  mkdir -p "${bin_dir}"
  mkdir -p "${src_dir}"

  # download samtools binary
  local version=`samtools_version`
  local url_base="https://github.com/samtools/samtools/releases/download/${version}"
  local fname="samtools-${version}.tar.bz2"
  wget -O "${src_dir}/${fname}" "${url_base}/${fname}"

  # extract and create symlinks
}

## convert GEO sample ID to SRA experiment ID

convert2expid(){
  local id=${1}
  gsm2srx="/home/`id -nu`/.dra/bin/gsm2srx.sh"
  if [[ ! -e "${gsm2srx}" ]] ; then
    # git clone https://github.com/inutano/dra_toolkit "/home/`id -nu`/.dra/src"
  fi
  ${gsm2srx} "${id}"
}

## get data from DRA, map reads to genome, output sorted/duplicate removed bam file

retrieve_and_mapping(){
  local genome_index_dir=${1}
  local exp_id=${2}
  local outdir=${3}

  local workdir=`init_workdir "${exp_id}" "${outdir}"`

  # Copy bam file if already available
  local backupdir="/home/`id -nu`/.dra/bam/${exp_id}"
  if [[ -e "${backupdir}" ]] ; then
    cp "${backupdir}/${exp_id}.bam" "${workdir}"
  else
    get_sequence_data "${exp_id}" "${workdir}"
    read_mapping "${genome_index_dir}" "${exp_id}" "${workdir}"
    sort_and_remove_duplicate "${exp_id}" "${workdir}"
  fi
}

init_workdir(){
  local exp_id=${1}
  local outdir=${2}
  workdir="${outdir}/${exp_id}"
  mkdir -p "${workdir}"
  echo "${workdir}"
}

get_sequence_data(){
  local exp_id=${1}
  local workdir=${2}
  get_dra="/home/`id -nu`/.dra/bin/get-dra.sh"
  if [[ ! -e "${get_dra}" ]] ; then
    # git clone https://github.com/inutano/ddbj_toolkit "/home/`id -nu`/.dra/bin"
  fi
  ${get_dra} ${exp_id} ${workdir}
}

read_mapping(){
  local genome_index_dir=${1}
  local exp_id=${2}
  local workdir=${3}

  format=`read_file_format "${exp_id}" "${workdir}"`
  layout=`read_layout "${exp_id}"`

  if [[ "${format}" = "sra" ]] ; then
    if [[ "${layout}" = "PAIRED" ]] ; then
      bowtie2_sra_paired "${genome_index_dir}" "${exp_id}" "${workdir}"
    elif [[ "${layout}" = "SINGLE" ]]; then
      bowtie2_sra_single "${genome_index_dir}" "${exp_id}" "${workdir}"
    fi
  elif [[ "${format}" = "fastq" ]]; then
    if [[ "${layout}" = "PAIRED" ]] ; then
      bowtie2_fq_paired "${genome_index_dir}" "${exp_id}" "${workdir}"
    elif [[ "${layout}" = "SINGLE" ]]; then
      bowtie2_fq_single "${genome_index_dir}" "${exp_id}" "${workdir}"
    fi
  fi
}

read_file_format(){
  local exp_id=${1}
  local workdir=${2}

  if [[ ! -z `ls "${workdir}" | grep "fastq"` ]] ; then
    echo "fastq"
  elif [[ ! -z `ls "${workdir}" | grep "sra"` ]] ; then
    echo "sra"
  fi
}

read_layout(){
  local exp_id=${1}
  # retrieve layout information from somewhere
}

bowtie2_sra_single(){
  local index_dir=${1}
  local exp_id=${2}
  local workdir=${3}

  local fastq_dump="/home/`id -nu`/.dra/bin/fastq-dump"
  local bowtie2_bin="/home/`id -nu`/.dra/bin/bowtie2"

  # execute fastq-dump and give stdin to bowtie2
  ${fastq_dump} --stdout "${workdir}/${exp_id}.sra" |\
  ${bowtie2_bin} -p 8 -t --no-unal -x "${index_dir}" -q - -S "${workdir}/${exp_id}.sam" 2> "${workdir}/bowtie2.log"
}

bowtie2_sra_paired(){
  local index_dir=${1}
  local exp_id=${2}
  local workdir=${3}

  local fastq_dump="/home/`id -nu`/.dra/bin/fastq-dump"
  local bowtie2_bin="/home/`id -nu`/.dra/bin/bowtie2"

  # execute fastq-dump and give stdin to bowtie2
  ${fastq_dump} --split-3 --outdir "${workdir}" "${workdir}/${exp_id}.sra"

  local forward=`ls "${workdir}" | grep "_1.fastq"`
  local reverse=`ls "${workdir}" | grep "_1.fastq"`

  ${bowtie2_bin} -p 8 -t --no-unal -x "${index_dir}" -q -1 "${workdir}/${forward}" -2 "${workdir}/${reverse}" -S "${workdir}/${exp_id}.sam" 2> "${workdir}/bowtie2.log"
}

bowtie2_fq_single(){
  local index_dir=${1}
  local exp_id=${2}
  local workdir=${3}

  local bowtie2_bin="/home/`id -nu`/.dra/bin/bowtie2"
  local fq_file=`ls "${workdir}" | grep "fastq"`

  ${bowtie2_bin} -p 8 -t --no-unal -x "${index_dir}" -q "${workdir}/${fq_file}" -S "${workdir}/${exp_id}.sam" 2> "${workdir}/bowtie2.log"
}

bowtie2_fq_paired(){
  local index_dir=${1}
  local exp_id=${2}
  local workdir=${3}

  local bowtie2_bin="/home/`id -nu`/.dra/bin/bowtie2"
  local forward=`ls "${workdir}" | grep "_1.fastq"`
  local reverse=`ls "${workdir}" | grep "_1.fastq"`

  ${bowtie2_bin} -p 8 -t --no-unal -x "${index_dir}" -q -1 "${workdir}/${forward}" -2 "${workdir}/${reverse}" -S "${workdir}/${exp_id}.sam" 2> "${workdir}/bowtie2.log"
}

sort_and_remove_duplicate(){
  local exp_id=${1}
  local workdir=${2}
  local samtools_bin="/home/`id -nu`/.dra/bin/samtools"


  # convert sam to bam
  ${samtools_bin} view -@ 4 -S -b -o "${workdir}/${exp_id}.raw.bam" "${workdir}/${exp_id}.sam"

  # sort
  ${samtools_bin} sort -@ 4 "${workdir}/${exp_id}.raw.bam" "${workdir}/${exp_id}.sorted.bam"

  # remove duplicate
  if [[ `read_layout "${exp_id}"` = "SINGLE" ]] ; then
    ${samtools_bin} rmdup -s "${workdir}/${exp_id}.sorted.bam" "${workdir}/${exp_id}.bam"
  else
    ${samtools_bin} rmdup "${workdir}/${exp_id}.sorted.bam" "${workdir}/${exp_id}.bam"
  fi
}


#
# variables
#

bowtie2_index_dir=${1}
sequencing_identifier=${2}
output_dir=${3}

#
# execute
#

install_tools
experiment_id=`convert2expid "${sequencing_identifier}"`
retrieve_and_mapping "${bowtie2_index_dir}" "${experiment_id}" "${output_dir}"
