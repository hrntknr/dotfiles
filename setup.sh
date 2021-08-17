#!/bin/bash
set -eu
cd $(dirname $0)

for file in $(find files -maxdepth 1 -type f); do
  srcFile=$(basename $file)
  dstFile=$HOME/${srcFile//@/\/}
  echo "copy src:$srcFile dst:$dstFile"
  if [ ! -e dstFile ];then
    mkdir -p $(dirname $dstFile)
  fi
  cp files/$srcFile $dstFile
done
