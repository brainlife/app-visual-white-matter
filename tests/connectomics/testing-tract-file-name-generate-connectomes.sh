#!/bin/bash

tracts=(*track*.tck)
for j in ${tracts[*]}
do
    bname=${j%.tck}
    echo $bname
done