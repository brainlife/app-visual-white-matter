#!/bin/bash
set -xe
# top variables
track=`jq -r '.track' config.json`
# parc=`jq -r '.parcellations' config.json`
#parc=./parc/parc.nii.gz
parc=`jq -r '.varea_parc' config.json` # visual areas parcellation
label=`jq -r '.varea_label' config.json` # visual areas parcellation

# both_endpoints=`jq -r '.both_endpoints' config.json`


# generate individual tracts for each index
tck2connectome ${track} ${parc} -out_assignments track_assignments.txt tmp.csv -force

# if [[ ${both_endpoints} != true ]]; then
# 	connectome2tck ${track}  track_assignments.txt track -file per_node
# 	if [ ! -f track/track.tck ]; then
# 		holder=(*track*.tck)
# 		tckedit ${holder[*]} track/track.tck
# 		tckinfo ./track/track.tck >> track/track_info.txt
# 	fi
# fi
