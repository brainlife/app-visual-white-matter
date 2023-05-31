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
tracts=(*track*.tck)

#### convert data to mif ####
# parcellation
if [ ! -f parc.mif ]; then
	echo "converting parcellation"
	mrconvert ${parc} parc.mif -force -nthreads ${ncores} -quiet
fi

#### conmat measures ####
conmat_measures="count density length denlen"

for j in ${tracts[*]}
do
    bname=${j%.tck}
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
done

# generate centers csv
# if [ ! -f ./connectomes/centers.csv ]; then
#     echo "creating csv for centers of nodes"
#     labelstats parc.mif -output centre | sed 's/^[[:space:]]*//' | tr -s '[:blank:]' ',' > ./connectomes/centers.csv
#     sed -e 's/\s\+/,/g' ./connectomes/centers.csv > tmp.csv
#     cat tmp.csv > ./connectomes/centers.csv
#     rm -rf tmp.csv  
# fi

# if [ -f ./connectomes/${bname}_count.csv ] && [ -f ./connectomes/${bname}_length.csv ]; then
# 	echo "generation of connectomes is complete!"
# 	mv *_assignments.csv ./connectomes/
# else
# 	echo "something went wrong"
# fi


## configurable inputs
# ad=`jq -r '.ad' config.json`
# fa=`jq -r '.fa' config.json`
# md=`jq -r '.md' config.json`
# rd=`jq -r '.rd' config.json`
# ga=`jq -r '.ga' config.json`
# ak=`jq -r '.ak' config.json`
# mk=`jq -r '.mk' config.json`
# rk=`jq -r '.rk' config.json`
# ndi=`jq -r '.ndi' config.json`
# odi=`jq -r '.odi' config.json`
# isovf=`jq -r '.isovf' config.json`
# t1_map=`jq -r '.T1map' config.json`
# r1_map=`jq -r '.R1map' config.json`
# m0_map=`jq -r '.M0map' config.json`
# pd_map=`jq -r '.PD' config.json`
# mtv_map=`jq -r '.MTV' config.json`
# vip_map=`jq -r '.VIP' config.json`
# sir_map=`jq -r '.SIR' config.json`
# wf_map=`jq -r '.WF' config.json`
# myelin_map=`jq -r '.myelin_map' config.json`
# sm=`jq -r '.sphmean' config.json`
# track=`jq -r '.track' config.json`
# weights=`jq -r '.weights' config.json`
# labels=`jq -r '.labels' config.json`




#### copy and subsample tractogram if labels available, else use weights
# if [ -f ${labels} ] && [ ! -f ${weights} ]; then
# 	weights=""

# 	# subsample tractogram based on labels datatype. assumes labels.csv is purely just binary assignment of streamlines (one value per row, len(streamlines) rows)
# 	connectome2tck ${track} ${labels} ./filtered_ -nodes 1 -exclusive -keep_self -nthreads 8 && mv ./filtered_* ./track.tck
# 	track=./track.tck
# elif [ ! -f ${labels} ] && [ -f ${weights} ]; then
# 	cp ${weights} ./weights.csv
# 	weights="-tck_weights_in ./weights.csv"
# elif [ ! -f ${labels} ] && [ ! -f ${weights} ]; then
# 	weights=""
# else # this condition is where both labels and weights are inputted. need to subselect the appropriate weights and subsample the tractogram

# 	# subsample tractogram
# 	connectome2tck ${track} ${labels} ./filtered_ -nodes 1 -exclusive -keep_self -nthreads 8 && mv ./filtered_* ./track.tck
# 	track=./track.tck

# 	# set weights to the new csv file generated
# 	weights="-tck_weights_in ./weights.csv"
# fi





#### set up measures variable if diffusion measures included. if not, measures is null and bypasses diffusion measures lines ####
# measures_to_loop="ad fa md rd ga ak mk rk ndi odi isovf t1_map r1_map m0_map pd_map mtv_map vip_map sir_map wf_map myelin_map sm"

# measures=""
# for i in ${measures_to_loop}
# do
# 	tmp=$(eval "echo \$${i}")

# 	if [ -f ${tmp} ]; then
# 		measures=$measures"${i} "
# 	fi
# done



## microstructural networks from diffusion data
# diffusion measures (if inputted)
# if [[ ! -z ${measures} ]]; then
# 	for MEAS in ${measures}
# 	do
# 		if [ ! -f ${MEAS}.mif ]; then
# 			echo "converting ${MEAS}"
# 			measure=$(eval "echo \$${MEAS}")
# 			mrconvert ${measure} ${MEAS}.mif -force -nthreads ${ncores} -force -quiet
# 		fi

# 		if [ ! -f ./connectomes/${MEAS}_mean.csv ]; then
# 			echo "creating connectome for diffusion measure ${MEAS}"
# 			# sample the measure for each streamline
# 			tcksample ${track} ${MEAS}.mif mean_${MEAS}_per_streamline.csv -stat_tck mean -use_tdi_fraction -nthreads ${ncores} -force

# 			# generate mean measure connectome
# 			tck2connectome ${track} parc.mif ./connectomes/${MEAS}_mean.csv -scale_file mean_${MEAS}_per_streamline.csv -stat_edge mean ${weights} ${cmd} -symmetric -zero_diagonal -nthreads ${ncores} -force

# 			# generate mean measure connectome weighted by density
# 			tck2connectome ${track} parc.mif ./connectomes/${MEAS}_mean_density.csv -scale_file mean_${MEAS}_per_streamline.csv -scale_invnodevol -stat_edge mean ${weights} ${cmd} -symmetric -zero_diagonal -nthreads ${ncores} -force

# 			# generate mean measure connectome weighted by streamline length
# 			if [[ ${length_vs_invlength} == 'true' ]]; then
# 				tck2connectome ${track} parc.mif ./connectomes/${MEAS}_mean_length.csv -scale_file mean_${MEAS}_per_streamline.csv -scale_invlength -stat_edge mean ${weights} ${cmd} -symmetric -zero_diagonal -nthreads ${ncores} -force

# 				# generate mean measure connectome weighted by density and streamline length
# 				tck2connectome ${track} parc.mif ./connectomes/${MEAS}_mean_denlen.csv -scale_file mean_${MEAS}_per_streamline.csv -scale_invnodevol -scale_invlength -stat_edge mean ${weights} ${cmd} -symmetric -zero_diagonal -nthreads ${ncores} -force
# 				echo "{\"tags\": [\"inv_length\" ]}" > product.json
# 			else
# 				tck2connectome ${track} parc.mif ./connectomes/${MEAS}_mean_length.csv -scale_file mean_${MEAS}_per_streamline.csv -scale_length -stat_edge mean ${weights} ${cmd} -symmetric -zero_diagonal -nthreads ${ncores} -force
				
# 				# generate mean measure connectome weighted by density and streamline length
# 				tck2connectome ${track} parc.mif ./connectomes/${MEAS}_mean_denlen.csv -scale_file mean_${MEAS}_per_streamline.csv -scale_invnodevol -scale_length -stat_edge mean ${weights} ${cmd} -symmetric -zero_diagonal -nthreads ${ncores} -force
# 				echo "{\"tags\": [\"length\" ]}" > product.json
# 			fi
# 		fi
# 	done
# fi