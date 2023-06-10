#!/bin/bash

# top variables
paAngle=`jq -r '.paAngle' config.json`
eccAngle=`jq -r '.eccAngle' config.json`
paMeridians=`jq -r '.paMeridians' config.json`
include_periph=`jq -r '.include_periph' config.json`
# minDegreePA=`jq -r '.min_degree_PA' config.json` # min degree for binning of polar angle
# maxDegreePA=`jq -r '.max_degree_PA' config.json` # max degree for binning of polar angle
# minDegreeECC=`jq -r '.min_degree_ECC' config.json` # min degree for binning of eccentricity
# maxDegreeECC=`jq -r '.max_degree_ECC' config.json` # max degree for binning of eccentricity

# build wedges
# set up variables
paMeridians=($paMeridians)
minDegreePA=""
maxDegreePA=""
minDegreeECC=""
maxDegreeECC=""

# build polar angle wedges
for (( i=0; i<${#paMeridians[*]}; i++ ))
do
	if [[ ${paMeridians[$i]} == "0" ]]; then
		minDegreePA=$minDegreePA" "${paMeridians[$i]}
	else
		minPA=$((${paMeridians[$i]} - $paAngle))
		echo $minPA

		if [[ ! $minPA -lt 0 ]]; then
			minDegreePA=$minDegreePA" "$minPA
		else
			minDegreePA=$minDegreePA" 0"
		fi
	fi

	if [[ ${paMeridians[$i]} == "180" ]]; then
		maxDegreePA=$maxDegreePA" "${paMeridians[$i]}
	else
		maxDegreePA=$maxDegreePA" "$((${paMeridians[$i]} + $paAngle))
	fi
done

# build eccentricity wedges
for (( i=0; i<=8; i+=$eccAngle ))
do
    maxECC=$(($i + $eccAngle))
    if [[ ! $i -eq 8 ]]; then
        if [[ $i -lt 8 ]] && [[ ! $maxECC -gt 8 ]]; then
            maxDegreeECC=$maxDegreeECC" "$maxECC
        else
            maxDegreeECC=$maxDegreeECC" 8"
        fi
    fi

    if [[ ! $i -eq 8 ]]; then
        minDegreeECC=$minDegreeECC" "$i
    fi
done

if [[ $include_periph == true ]]; then
    maxDegreeECC=$maxDegreeECC" 90"
    minDegreeECC=$minDegreeECC" 8"
fi

# make loopable
minDegreePA=($minDegreePA)
maxDegreePA=($maxDegreePA)
minDegreeECC=($minDegreeECC)
maxDegreeECC=($maxDegreeECC)

# loop through all bins and create single volume, then multiply binary file by number of degree bins so we can create one large parcellation
ctr=0
for DEG_PA in ${!minDegreePA[@]}; do
	if [[ $(($maxDegreePA[$DEG_PA]-$paAngle)) -eq 90 ]] && [[ $(($minDegreePA[$DEG_PA]+$paAngle)) -eq 90 ]]; then
		angle_hem="hm"
	else
		angle_hem="vm_or_diagonal"
	fi
	for DEG_ECC in ${!minDegreeECC[@]}; do
		# combine hemispheres into one single volume
		[ ! -f polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz ] && fslmaths lh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz -add rh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz -bin polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz

		if [[ ${angle_hem} == "hm" ]]; then
			[ ! -f lh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz ] && fslmaths lh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz -mul $((ctr+1)) lh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz
			
			[ ! -f rh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+2)).nii.gz ] && fslmaths rh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz -mul $((ctr+2)) rh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+2)).nii.gz

			if [[ $ctr -eq 0 ]]; then
				holder="fslmaths lh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz -add rh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+2)).nii.gz"
			else
				holder="$holder -add lh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz -add rh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+2)).nii.gz"
			fi
			holder2="$holder2 lh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz
			rh.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+2)).nii.gz"

			ctr=$((ctr+2))
		else
			# multiply by parcellation number (i.e. DEG; +1 because 0 index)
			[ ! -f polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz ] && fslmaths polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz -mul $((ctr+1)) polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz

			# make combination easier by creating holder variable to pass into fslmaths
			if [[ $ctr -eq 0 ]]; then
				holder="fslmaths polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz"
			else
				holder="$holder -add polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz"
			fi
			holder2="$holder2 polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}_parc$((ctr+1)).nii.gz"
			ctr=$((ctr+1)) 
		fi
	done
done

# create final parcellation
if [ ! -f parc/parc.nii.gz ]; then
	${holder} ./parc/parc.nii.gz
fi

# create label and key files
# FILES=(`echo "*_parc*.nii.gz"`)
holder2=($holder2)
for i in "${!holder2[@]}"
do
	name=`echo ${holder2[$i]} | cut -d'_' -f1`
	oldval=$((i+1))

	newval=$oldval
	echo -e "${oldval}\t->\t${newval}\t== ${name}" >> key.txt

	# make tmp.json containing data for labels.json
	jsonstring=`jq --arg key0 'name' --arg value0 "${name}" --arg key1 "desc" --arg value1 "value of ${newval} indicates voxel belonging to polarAngle x eccentricity bin ${name}" --arg key2 "voxel_value" --arg value2 ${newval} --arg key3 "label" --arg value3 ${newval} '. | .[$key0]=$value0 | .[$key1]=$value1 | .[$key2]=$value2 | .[$key3]=$value3' <<<'{}'`
	if [ ${i} -eq 0 ] && [ ${newval} -eq ${#holder2[*]} ]; then
		echo -e "[\n${jsonstring}\n]" >> tmp.json
	elif [ ${i} -eq 0 ]; then
		echo -e "[\n${jsonstring}," >> tmp.json
	elif [ ${newval} -eq ${#holder2[*]} ]; then
		echo -e "${jsonstring}\n]" >> tmp.json
	else
		echo -e "${jsonstring}," >> tmp.json
	fi
done

# move label and key files to proper location
[ ! -f parc/label.json ] & [ -f tmp.json ] && mv tmp.json ./parc/label.json
[ ! -f parc/key.txt ] & [ -f key.txt ] && mv key.txt ./parc/key.txt

# final check
# if [ ! -f parc/parc.nii.gz ]; then
# 	echo "something went wrong. check deriviatives and logs"
# 	exit 1
# else
# 	echo "parcellation generation complete."
# 	mv *.nii.gz *.txt *.gii *.pial ./raw/
# 	exit 0
# fi
