#!/usr/bin/env python3

import os,sys
import glob
import pandas as pd
import pybrainlife.data.manipulate as blmanip
import jgf
import igraph
import json

def build_network_df(paths,subjectID,sessionID):

    df = pd.DataFrame()
    igraphs = []
    tags = []
    datatype_tags = []
    parcellation = []
    measure = []

    for i in paths:
        bname, conmat_measure = i.split('./networks/')[1].split('/')[:-2]
        tmp = jgf.igraph.load(i,compressed=True)
        igraphs = igraphs + [tmp[0]]
        tags = tags + [i.split('./networks/')[1].split('/')[:-2]]
        datatype_tags = datatype_tags + ['measurements']
        parcellation = parcellation + [bname]
        measure = measure + [conmat_measure]
    
    df['subjectID'] = [ subjectID for f in range(len(igraphs)) ]
    df['sessionID'] = [ sessionID for f in range(len(igraphs)) ]
    df['igraph'] = igraphs
    df['tags'] = tags
    df['datatype_tags'] = datatype_tags
    df['parcellation'] = parcellation
    df['measure'] = measure

    return df

def main():

    with open('config.json') as config_f:
        config = json.load(config_f)

    subjectID = config['_inputs'][0]['meta']['subject']

    if 'session' in config['_inputs'][0]['meta'].keys():
        sessionID = config['_inputs'][0]['meta']['session']
    else:
        sessionID = '1'

    if not os.path.isdir('net-stats'):
        os.mkdir('net-stats')
        os.mkdir('net-stats/net-stats')

    measurements_paths = glob.glob('./networks/*/*/measurements/network.json.gz')

    networks_df = build_network_df(measurements_paths,subjectID,sessionID)

    conmats, global_measures, local_measures = blmanip.parse_networks(networks_df)

    conmats['parcellation'] = conmats.apply(lambda x: x['tags'][0], axis=1).tolist()
    conmats['measure'] = conmats.apply(lambda x: x['tags'][1], axis=1).tolist()
    conmats = conmats.drop(columns=['tags','datatype_tags'])

    global_measures = global_measures.reset_index(drop=True)
    global_measures['parcellation'] = global_measures.apply(lambda x: x['tags'][0], axis=1).tolist()
    global_measures['measure'] = global_measures.apply(lambda x: x['tags'][1], axis=1).tolist()
    global_measures = global_measures.drop(columns=['tags','datatype_tags'])

    local_measures = local_measures.reset_index(drop=True)
    local_measures['parcellation'] = local_measures.apply(lambda x: x['tags'][0], axis=1).tolist()
    local_measures['measure'] = local_measures.apply(lambda x: x['tags'][1], axis=1).tolist()
    local_measures = local_measures.drop(columns=['tags','datatype_tags'])

    conmats.to_csv('./net-stats/net-stats/conmats.csv')
    global_measures.to_csv('./net-stats/net-stats/global_measures.csv',index=False)
    local_measures.to_csv('./net-stats/net-stats/local_measures.csv',index=False)

if __name__ == "__main__":
    main()

