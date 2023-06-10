#!/bin/bash

# output lines to log files and fail if error
# set -x
# set -e

# parse inputs
prfSurfacesDir=`jq -r '.prfSurfacesDir' config.json`
prfVerticesDir=`jq -r '.prfVerticesDir' config.json`
paAngle=`jq -r '.paAngle' config.json`
eccAngle=`jq -r '.eccAngle' config.json`
paMeridians=`jq -r '.paMeridians' config.json`
include_periph=`jq -r '.include_periph' config.json`
# minDegreePA=`jq -r '.min_degree_PA' config.json` # min degree for binning of polar angle
# maxDegreePA=`jq -r '.max_degree_PA' config.json` # max degree for binning of polar angle
# minDegreeECC=`jq -r '.min_degree_ECC' config.json` # min degree for binning of eccentricity
# maxDegreeECC=`jq -r '.max_degree_ECC' config.json` # max degree for binning of eccentricity
dwi=`jq -r '.dwi' config.json`
fmri=`jq -r '.func' config.json`
freesurfer=`jq -r '.freesurfer' config.json`
inputparc=`jq -r '.inputparc' config.json`
hemispheres="lh rh"

# make directories
[ ! -d parc ] && mkdir parc
[ ! -d raw ] && mkdir raw

# copy freesurfer
[ ! -d output ] && cp -RL ${freesurfer} ./output && freesurfer="./output"

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
echo ${maxDegreeECC[*]}

# set up some stuff to move inputaparc to space
if [ -f ${dwi} ]; then
	input_nii_gz=$dwi
elif [ -f ${fmri} ]; then
	input_nii_gz=$fmri
else
	input_nii_gz="./ribbon.nii.gz"
fi

# source $FREESURFER_HOME/SetUpFreeSurfer.sh

# set SUBJECTS_DIR
export SUBJECTS_DIR=${freesurfer}

# inputaparc to diffusion space
[ ! -f ${inputparc}+aseg.nii.gz ] && mri_label2vol --seg $freesurfer/mri/${inputparc}+aseg.mgz --temp $input_nii_gz --regheader $freesurfer/mri/${inputparc}+aseg.mgz --o ${inputparc}+aseg.nii.gz

# use this as internal target for volume moves
input_nii_gz="${inputparc}+aseg.nii.gz"

# move freesurfer whole-brain ribbon into diffusion space
[ ! -f ribbon.nii.gz ] && mri_convert ${freesurfer}/mri/ribbon.mgz ./ribbon.nii.gz

# loop through hemispheres and create polar angle surfaces
for hemi in ${hemispheres}
do
	echo "converting files for ${hemi}"

	# move freesurfer hemisphere ribbon into diffusion space
	[ ! -f ${hemi}.ribbon.nii.gz ] && mri_convert $freesurfer/mri/${hemi}.ribbon.mgz ./${hemi}.ribbon.nii.gz

	# convert pial to gifti
	[ ! -f ${hemi}.pial ] && mris_convert ${freesurfer}/surf/${hemi}.pial ./${hemi}.pial

	# convert polar angle surface to gifti
	[ ! -f ${hemi}.polarAngle.func.gii ] && mris_convert -c ${prfSurfacesDir}/${hemi}.polarAngle ./${hemi}.pial ${hemi}.polarAngle.func.gii
	[ ! -f ${hemi}.eccentricity.func.gii ] && mris_convert -c ${prfSurfacesDir}/${hemi}.eccentricity ./${hemi}.pial ${hemi}.eccentricity.func.gii

	# create mask of visual occipital lobe
	[ ! -f ${hemi}.mask.func.gii ] && wb_command -metric-math 'x / x' -var x ${hemi}.polarAngle.func.gii ${hemi}.mask.func.gii

	# loop through degrees and create individual nifti files for each bin and hemisphere
	for DEG_PA in ${!minDegreePA[@]}; do
		# genereate polarAngle bin surfaces and mask eccentricities
		[ ! -f ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.func.gii ] && mri_binarize --i ./${hemi}.polarAngle.func.gii --min ${minDegreePA[$DEG_PA]} --max ${maxDegreePA[$DEG_PA]} --o ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.func.gii && wb_command -metric-mask ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.func.gii ./${hemi}.mask.func.gii ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.func.gii
	done

	for DEG_ECC in ${!minDegreeECC[@]}; do
		# genereate polarAngle bin surfaces and mask eccentricities
		[ ! -f ./${hemi}.eccentricity${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.func.gii ]  && mri_binarize --i ./${hemi}.eccentricity.func.gii --min ${minDegreeECC[$DEG_ECC]} --max ${maxDegreeECC[$DEG_ECC]} --o ./${hemi}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.func.gii && wb_command -metric-mask ./${hemi}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.func.gii ./${hemi}.mask.func.gii ./${hemi}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.func.gii
	done

	for DEG_PA in ${!minDegreePA[@]}; do
		for DEG_ECC in ${!minDegreeECC[@]}; do
			[ ! -f ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.func.gii ] && wb_command -metric-mask ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.func.gii ./${hemi}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.func.gii ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.func.gii

			# create volume-based binned file
			[ ! -f ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz ] && mri_surf2vol --o ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz --subject ./ --so ./${hemi}.pial ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.func.gii && mri_vol2vol --mov ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz --targ ${input_nii_gz} --regheader --o ./${hemi}.polarAngle${minDegreePA[$DEG_PA]}to${maxDegreePA[$DEG_PA]}.eccentricity${minDegreeECC[$DEG_ECC]}to${maxDegreeECC[$DEG_ECC]}.nii.gz --nearest
		done
	done
done