#!/bin/bash

#nodes=1:ppn=2,walltime=1:00:00
#visual-white-matter-connectomics-parcellation-generator

# create niftis of eccentricity parcellations before final merge
# echo $FREESURFER_LICENSE > license.txt
cat $FREESURFER_LICENSE > license.txt
time singularity exec -e -B `pwd`/license.txt:/usr/local/freesurfer/license.txt docker://brainlife/connectome_workbench:1.4.2-freesurfer-update ./src/connectomics/parcellation-generator/polar-angle-by-eccentricity-nifti-generator.sh

# create final parcellation
if [ ! -f parc/parc.nii.gz ]; then
    time singularity exec -e docker://brainlife/fsl:5.0.11 ./src/connectomics/parcellation-generator/combine-parcellation.sh
fi
