#!/bin/bash

command="node js/index.js" # <== Change this
log_file="./out.log"
timestamp=$(TZ=EST date +%T_%Z)

echo "" >> $log_file
echo "============================ $timestamp ============================" >> $log_file

$command 2>&1 | tee -a "$log_file"