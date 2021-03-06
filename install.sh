#!/bin/bash
#
# install script for dratools
#
set -eu

#
# check dependencies
#
if [ -z `which git` ]; then
  echo "Error: You need git to install dratools."
  exit 1
fi

#
# set empty variables for command line option
#
TARGET_DIR=

#
# parse command line option
#
while [[ $# > 1 ]]; do
  key=$1
  case "${key}" in
    -t|--target-dir)
    TARGET_DIR=$2
    shift
    ;;
  esac
  shift
done

#
# fetch repository from github
#

# set default target dir
if [[ -z "${TARGET_DIR}" ]]; then
  TARGET_DIR="${HOME}/.dra"
fi

# target direcotry should not exist
if [[ -e "${TARGET_DIR}" ]]; then
  echo "Error: File already exists: ${TARGET_DIR}"
  exit 1
fi

# fetch repository
git clone https://github.com/inutano/dratools "${TARGET_DIR}"

#
# rewrite paths
#
dratools_bin="${TARGET_DIR}/bin/dratools"
cat "${dratools_bin}" | sed -e 's:^DRATOOLS_BASE.+$:DRATOOLS_BASE='"${TARGET_DIR}"':' > "${dratools_bin}"
