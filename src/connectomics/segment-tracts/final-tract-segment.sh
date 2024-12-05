#!/bin/bash
set -xe
# top variables
track=`jq -r '.track' config.json`

# connectome2tck ${track} assignments_endpoints.txt track -file per_node
connectome2tck ${track} assignments_endpoints.txt track -file per_edge

# create new tractogram
if [ ! -f track/track.tck ]; then
	holder=(*track*.tck)
	tckedit ${holder[*]} track/track.tck
	tckinfo ./track/track.tck >> track/track_info.txt
fi
