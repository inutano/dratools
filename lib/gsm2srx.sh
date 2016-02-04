#!/bin/bash
#
# gsm2sra v0.1.0 by inutano@gmail.com
#
# usage:
#   ./gsm2sra.sh <GEO Sample ID>
#
set -eu

#
# functions
#
gsm2srx(){
  local gsm_id=${1}
  echo "DRX000001"
}

#
# variables
#
geo_sample_id=${1}


#
# execute
#
experiment_id=`gsm2srx "${geo_sample_id}"`
echo "${experiment_id}"
