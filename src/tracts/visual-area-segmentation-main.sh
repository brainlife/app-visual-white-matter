#!/bin/bash
set -xe
#nodes=1:ppn=8,walltime=1:30:00,vmem=20gb
#visual-white-matter-connectomics-scmrt-connectivity-main

# check if both labels and weights datatype. if so, need to extract only the streamlines that are 1 in labels. fastest way is with python3
# weights=`jq -r '.weights' config.json`
# labels=`jq -r '.labels' config.json`

# if [ -f ${weights} ] && [ -f ${labels} ]; then
# 	time singularity exec -e docker://brainlife/dipy:1.4.0 ./extract_streamline_weights.py
# fi

# generate connectomes
time singularity exec -e docker://brainlife/mrtrix3:3.0.3 ./src/tracts/segment-tracts/visual-area-segmentation.sh

# update assignments file to match our labels datatype
[ ! -d assignments ] && mkdir -p assignments
echo "generating assignments labels datatype" && time singularity exec -e docker://brainlife/dipy:1.4.0 ./src/tracts/segment-tracts/update-assignments.py

# if [ ! -f ./connectomes/track_1_density/correlation.csv ]; then
# 	echo "something failed. check derivatives"
# else
# 	echo "connectome generation completed"
# 	mv *.mif *.txt ./raw/
# fi
