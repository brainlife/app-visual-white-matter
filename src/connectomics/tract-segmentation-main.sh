#!/bin/bash
#nodes=1:ppn=1,walltime=1:30:00
#visual-white-matter-connectomics-tract-segmentation

[ ! -d track ] && mkdir track
[ ! -d raw ] && mkdir raw

# create assignments for each tract and parcel in parcellations
if [ ! -f tmp.csv ]; then
	time singularity exec -e docker://brainlife/mrtrix3:3.0.0 ./src/connectomics/segment-tracts/initial-tract-segment.sh
fi

if [ ! -f track/track.tck ]; then
	time singularity exec -e docker://brainlife/pyafq:1.0 ./src/connectomics/segment-tracts/cleanup-assignments.py
	time singularity exec -e docker://brainlife/mrtrix3:3.0.0 ./src/connectomics/segment-tracts/final-tract-segment.sh
fi

# final check
if [ ! -f track/track.tck ]; then
	echo "segmentation failed. see logs and derivatives"
	exit 1
else
	echo "segmentation complete"
	mv *.txt *.csv *.nii.gz *.tck ./raw/
	exit 0
fi
