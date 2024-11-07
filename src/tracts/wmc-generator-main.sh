#!/bin/bash
set -xe
#nodes=1:ppn=16,vmem=28gb,walltime=1:00:00
#visual-white-matter-connectomics-wmc-generator

mkdir -p wmc wmc/tracts wmc/surfaces

# convert to wmc
if [ ! -f ./wmc/classification.mat ]; then
	time singularity exec -e docker://brainlife/pyafq:0.4.1-pandas-update ./src/tracts/wmc-generator/generate-wmc.py
fi

# create surfaces for visualizer
if [ ! -f ./wmc/surfaces/index.json ]; then
	time singularity exec -e docker://brainlife/pythonvtk:1.1 ./src/tracts/wmc-generator/parcellation2vtk.py
fi

# cleanup file names
time singularity exec -e docker://filsilva/cxnetwork:0.2.0 ./src/tracts/wmc-generator/clean-up-file-names.py
