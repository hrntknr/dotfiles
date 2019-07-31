#!/bin/bash
for file in $(find files -maxdepth 1 -type f); do
  srcFile=$(basename $file)
  dstFile=$HOME/${srcFile//@/\/}
  if [ ! -e dstFile ];then
    mkdir -p $(dirname $dstFile)
  fi
  cp files/$srcFile $(dirname $dstFile)
done
