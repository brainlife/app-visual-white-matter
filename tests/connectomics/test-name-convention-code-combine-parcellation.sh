#!/bin/bash

minDegreePA="0 35 80 125 160" # min degree for binning of polar angle
maxDegreePA="20 55 100 145 180" # max degree for binning of polar angle
minDegreeECC="0 1 2 3 4 5 6 7 8" # min degree for binning of eccentricity
maxDegreeECC="1 2 3 4 5 6 7 8 90" # max degree for binning of eccentricity

minDegreePA=($minDegreePA)
maxDegreePA=($maxDegreePA)
minDegreeECC=($minDegreeECC)
maxDegreeECC=($maxDegreeECC)

ctr=0
for DEG_PA in ${!minDegreePA[@]}; do
	for DEG_ECC in ${!minDegreeECC[@]}; do
        [ ! -f polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz ] && touch polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz
        ctr=$((ctr+1))
    done
done

FILES=(`echo "*_parc*.nii.gz"`)
for i in "${!FILES[@]}"
do
	name=`echo ${FILES[$i]} | cut -d'_' -f1`
    # echo $name
	oldval=$((i+1))

	newval=$oldval
	echo -e "${oldval}\t->\t${newval}\t== ${name}" >> key.txt

	# make tmp.json containing data for labels.json
	jsonstring=`jq --arg key0 'name' --arg value0 "${name}" --arg key1 "desc" --arg value1 "value of ${newval} indicates voxel belonging to polarAngle x eccentricity bin ${name}" --arg key2 "voxel_value" --arg value2 ${newval} --arg key3 "label" --arg value3 ${newval} '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2 | .[$key3]=$value3' <<<'{}'`
	if [ ${i} -eq 0 ] && [ ${newval} -eq ${#FILES[*]} ]; then
		echo -e "[\n${jsonstring}\n]" >> tmp.json
	elif [ ${i} -eq 0 ]; then
		echo -e "[\n${jsonstring}," >> tmp.json
	elif [ ${newval} -eq ${#FILES[*]} ]; then
		echo -e "${jsonstring}\n]" >> tmp.json
	else
		echo -e "${jsonstring}," >> tmp.json
	fi
done
