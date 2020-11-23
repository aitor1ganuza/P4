#!/bin/bash

## \file
## \TODO This file implements a very trivial feature extraction; use it as a template for other front ends.
## 
## Please, read SPTK documentation and some papers in order to implement more advanced front ends.

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 4 ]]; then
   echo "$0 lpc_order lpcc_order input.lp output.lpcc"
   exit 1
fi

lpc_order=$1
lpcc_order=$2
inputfile=$3
outputfile=$4
#No estoy seguro si es así o hay que añadirlo como argumento de entrada al programa


UBUNTU_SPTK=1
if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   LPCC="sptk lpc2c"
else
   # or install SPTK building it from its source
   LPCC="lpc2c"
fi

# Main command for feature extration
$LPCC -m $lpc_order -M $lpcc_order $inputfile > $base.lpcc

# Our array files need a header with the number of cols and rows:
ncol=$((lpcc_order)) # lpcc p =>  (c0 c1 c2 ... cp) 
nrow=`$X2X +fa < $base.lpcc | wc -l | perl -ne 'print $_/'$ncol', "\n";'`

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
cat $base.lpcc >> $outputfile

exit