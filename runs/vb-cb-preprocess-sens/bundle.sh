#!/bin/bash

fs=`tail -n10 results/best_seeds.txt | grep -oP "results/p\d+\.\d+_seed\d+"`

mkdir -p results/bundle
rm -rf results/bundle/*

for f in $fs
do
  dest=`echo $f | grep -oP "p\d+\.\d+"`
  cp -r $f results/bundle/$dest
done
