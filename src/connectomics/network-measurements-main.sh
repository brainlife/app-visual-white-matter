#!/bin/bash

#nodes=1:ppn=1,vmem=6gb,walltime=01:00:00
#visual-white-matter-connectomics-network-measurements

files=(`find ./networks/track* -maxdepth 0 -type d`)
conmats="count density length denlen"
richClubPercentage=`jq -r '.richClubPercentage' config.json`

for j in ${files[*]}
do
    # grab base name
    bname=${j##./networks/}
    for i in ${conmats}
    do
        fstem=./networks/${bname}/${i}/
        
        # network
        network=${fstem}/network.json.gz

        # create temporary config.json
        cat << EOF > tmp.json
{
    "network": "${network}",
    "richClubPercentage": "${richClubPercentage}"
}
EOF
        echo $bname $i
        [ ! -f ./networks/${bname}/${i}/measurements/network.json.gz ] && singularity exec -e docker://filsilva/cxnetwork:0.2.0 ./src/connectomics/network-measurements/network-measurements.py tmp.json ./networks/${bname}/${i}/measurements

        rm -rf tmp.json
    done
done

# clean up file names
singularity exec -e docker://filsilva/cxnetwork:0.2.0 ./src/connectomics/network-measurements/clean-up-file-names.py