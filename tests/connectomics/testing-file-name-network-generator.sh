#!/bin/bash

[ ! -d ./connectomes ] && mkdir ./connectomes
conmats="count density length denlen"

for (( i=1; i<51; i++ ))
do 
    for j in ${conmats}
    do
        [ ! -d ./connectomes/track_${i}/${j}_out ] && mkdir ./connectomes/track_${i}/ ./connectomes/track_${i}/${j}_out
    done
done

files=(`find ./connectomes -name track_* -type d -maxdepth 1`)
echo ${files}
for j in ${files[*]}
do
    echo ${j##./connectomes/}
done
