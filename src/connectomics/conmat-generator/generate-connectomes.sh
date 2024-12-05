#!/bin/bash

set -x
set -e

mkdir -p connectomes labels raw

#### configurable parameters ####
parc=`jq -r '.varea_parc' config.json` # visual areas parcellation
label=`jq -r '.varea_label' config.json` # visual areas parcellation
assignment_radial_search=`jq -r '.assignment_radial_search' config.json` # numerical: default is 4mm
assignment_reverse_search=`jq -r '.assignment_reverse_search' config.json` # numerical
assignment_forward_search=`jq -r '.assignment_forward_search' config.json` # numerical
length_vs_invlength=`jq -r '.inverse_length' config.json` # boolean: true == normalize length by invlen; false == normalize by len
ncores=8

# define functions
convert_to_csv () {
    sed -e 's/\s\+/,/g' $1/csv/correlation.csv > $1/csv/tmp.csv
    cat $1/csv/tmp.csv > $1/csv/correlation.csv
    rm -rf $1/csv/tmp.csv
} 

#### set up input argument commands
cmd=""
if [[ ! ${assignment_radial_search} == "4" ]]; then
	cmd=$cmd" -assignment_radial_search ${assignment_radial_search}"
fi

if [[ ! ${assignment_reverse_search} == "" ]]; then
	cmd=$cmd" -assignment_reverse_search ${assignment_reverse_search}"
fi

if [[ ! ${assignment_forward_search} == "" ]]; then
	cmd=$cmd" -assignment_forward_search ${assignment_forward_search}"
fi

weights=""
# tracts=(*track*.tck)

#### convert data to mif ####
# parcellation
if [ ! -f parc.mif ]; then
	echo "converting parcellation"
	mrconvert ${parc} parc.mif -force -nthreads ${ncores} -quiet
fi

#### conmat measures ####
conmat_measures="count density length denlen"

# for j in ${tracts[*]}
# do
#     bname=${j%.tck}
bname=track
j=track/track.tck
for i in ${conmat_measures}
do
    mkdir -p ./connectomes/${bname} ./connectomes/${bname}/${i}_out ./connectomes/${bname}/${i}_out/csv
done

#### generate connectomes ####
# count network
if [ ! -f ./connectomes/${bname}_count.csv ]; then
    echo "creating connectome for streamline count"
    tck2connectome ${j} parc.mif ./connectomes/${bname}_count.csv -out_assignments ./connectomes/${bname}_assignments.csv ${weights} ${cmd} -symmetric -zero_diagonal -force -nthreads ${ncores}

    cp ./connectomes/${bname}_count.csv ./connectomes/${bname}/count_out/csv/correlation.csv
    cp ${label} ./connectomes/${bname}/count_out/
    cp ./src/connectomics/conmat-generator/index.json ./connectomes/${bname}/count_out/
    convert_to_csv ./connectomes/${bname}/count_out

    sed 1,1d ./connectomes/${bname}_assignments.csv > tmp.csv
    cat tmp.csv > ./connectomes/${bname}_assignments.csv
    rm -rf tmp.csv
fi

# count density network
if [ ! -f ./connectomes/${bname}_density.csv ]; then
    echo "creating connectome for streamline density"
    tck2connectome ${j} parc.mif ./connectomes/${bname}_density.csv -scale_invnodevol ${weights} ${cmd} -symmetric -zero_diagonal -force -nthreads ${ncores}

    cp ./connectomes/${bname}_density.csv ./connectomes/${bname}/density_out/csv/correlation.csv
    cp ${label} ./connectomes/${bname}/density_out/
    cp ./src/connectomics/conmat-generator/index.json ./connectomes/${bname}/density_out/
    convert_to_csv ./connectomes/${bname}/density_out
fi

# length network
if [ ! -f ./connectomes/${bname}_length.csv ]; then
    echo "creating connectome for streamline length"
    if [[ ${length_vs_invlength} == "true" ]]; then
        tck2connectome ${j} parc.mif ./connectomes/${bname}_length.csv -scale_length -stat_edge mean ${weights} ${cmd} -symmetric -zero_diagonal -force -nthreads ${ncores}
    else
        tck2connectome ${j} parc.mif ./connectomes/${bname}_length.csv -scale_invlength -stat_edge mean ${weights} ${cmd} -symmetric -zero_diagonal -force -nthreads ${ncores}
    fi
    cp ./connectomes/${bname}_length.csv ./connectomes/${bname}/length_out/csv/correlation.csv
    cp ${label} ./connectomes/${bname}/length_out/
    cp ./src/connectomics/conmat-generator/index.json ./connectomes/${bname}/length_out/
    convert_to_csv ./connectomes/${bname}/length_out
fi

# density of length network
if [ ! -f ./connectomes/${bname}_denlen.csv ]; then
    echo "creating connectome for streamline length"
    if [[ ${length_vs_invlength} == "true" ]]; then
        tck2connectome ${j} parc.mif ./connectomes/${bname}_denlen.csv -scale_length -stat_edge mean -scale_invnodevol ${weights} ${cmd} -symmetric -zero_diagonal -force -nthreads ${ncores}
    else
        tck2connectome ${j} parc.mif ./connectomes/${bname}_denlen.csv -scale_invlength -stat_edge mean -scale_invnodevol ${weights} ${cmd} -symmetric -zero_diagonal -force -nthreads ${ncores}
    fi
    cp ./connectomes/${bname}_denlen.csv ./connectomes/${bname}/denlen_out/csv/correlation.csv
    cp ${label} ./connectomes/${bname}/denlen_out/
    cp ./src/connectomics/conmat-generator/index.json ./connectomes/${bname}/denlen_out/
    convert_to_csv ./connectomes/${bname}/denlen_out
fi
# done