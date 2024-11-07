#!/bin/bash
#nodes=1:ppn=8,walltime=1:30:00,vmem=20gb
#visual-white-matter-connectomics-cortexmap-generator-main
set -xe

echo "mapping measures to cortical surface"
time singularity exec -e -B `pwd`/license.txt:/usr/local/freesurfer/license.txt docker://brainlife/connectome_workbench:1.5.0 ./src/connectomics/cortexmap-generator/cortex-mapping-pipeline.sh
