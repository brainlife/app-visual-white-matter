#!/bin/bash

#nodes=1:ppn=1,vmem=6gb,walltime=01:00:00
#visual-white-matter-connectomics-network-generator

SINGULARITYENV_PYTHONNOUSERSITE=true 

[ ! -d networks ] && mkdir networks

# conmats
conmats="count density length denlen"


files=(`find ./connectomes/track* -maxdepth 0 -type d`)

for j in ${files[*]}
do
    # grab base name
    bname=${j##./connectomes/}
    for i in ${conmats}
    do
        fstem=./connectomes/${bname}/${i}_out/
        
        # grab label
        label=${fstem}/label.json

        # grab correlation
        correlation=${fstem}/csv/

        # grab index
        index=${fstem}/index.json

        # create temporary config.json
        cat << EOF > tmp.json
{
    "index": "${index}",
    "label": "${label}",
    "csv": "${correlation}"
}
EOF
        echo $bname $i
        [ ! -f ./networks/${bname}/${i}/network.json.gz ] && singularity exec -e docker://filsilva/cxnetwork:0.2.0 ./src/connectomics/network-generator/network-generator.py tmp.json ./networks/${bname}/${i}

        rm -rf tmp.json
    done
done
echo "done"



