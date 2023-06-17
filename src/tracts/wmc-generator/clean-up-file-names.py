#!/usr/bin/env python3

import glob
import pandas as pd
import os

labels = pd.read_json('./parc/label.json',orient='records')
# conmats = glob.glob('./assignments/track*/')
# networks = glob.glob('./networks/track*/')
csvs = glob.glob('./assignments/track*_*')
tracks = glob.glob('./track*.tck')

for i in range(len(csvs)):
    stem = int(csvs[i].split('./assignments/track')[1].replace('/',''))
    name = labels.loc[labels['voxel_value'] == stem]['name'].values[0].replace('.','-')
    track = [ f for f in tracks if f.split('./')[1].split('.tck')[0] == 'track'+str(stem) ][0]
    # os.rename(csvs[i],'./assignments/'+name)
    # os.rename(networks[i],'./networks/'+name)
    # os.rename(track,name+'.tck')

    csv = [ f for f in csvs if f.split('./assignments/')[1].split('_')[0] == 'track'+str(stem) ]
    for j in csv:
        os.rename(j,'./assignments/'+name+'_'+j.split('_')[1])