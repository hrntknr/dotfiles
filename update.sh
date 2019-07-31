#!/bin/bash
for file in $(find files -maxdepth 1 -type f); do
  dstFile=$(basename $file)
  srcFile=$HOME/${dstFile//@/\/}
  cp $srcFile files/$dstFile
done
