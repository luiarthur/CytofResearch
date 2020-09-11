#!/bin/bash

RESULTS_DIR=$1

fs=`tail -n10 ${RESULTS_DIR}/best_seeds.txt | grep -oP "$RESULTS_DIR/p\d+\.\d+_seed\d+"`

mkdir -p $RESULTS_DIR/bundle
rm -rf $RESULTS_DIR/bundle/*

for f in $fs
do
  dest=`echo $f | grep -oP "p\d+\.\d+"`
  cp -r $f $RESULTS_DIR/bundle/$dest
done
