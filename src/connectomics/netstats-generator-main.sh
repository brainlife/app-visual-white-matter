#!/bin/bash

#nodes=1:ppn=2,walltime=1:00:00
#visual-white-matter-connectomics-netstats-generator

time singularity exec -e docker://brainlife/ga-python:lab328-dipy141-pybrainlife-1.0 ./src/connectomics/netstats-generator/generate-netstats.py