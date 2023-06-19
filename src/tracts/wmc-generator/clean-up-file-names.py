#!/usr/bin/env python3

import glob
import pandas as pd
import os

labels = pd.read_json('./parc/label.json',orient='records')
subjdirs = glob.glob('./assignments/track*/')
# networks = glob.glob('./networks/track*/')
assignments = glob.glob('./assignments/track*_assignments.csv')
csvs = glob.glob('./assignments/track*_*.csv')
tracks = glob.glob('./track*.tck')

for i in range(len(assignments)):
    # stem = int(csvs[i].split('./assignments/track')[1].replace('/',''))
    stem = assignments[i].split('./assignments/track')[-1].split('_')[0]
    name = labels.loc[labels['voxel_value'] == int(stem)]['name'].values[0].replace('.','-')
    print(name)
    track = [ f for f in tracks if f.split('./')[1].split('.tck')[0] == 'track'+str(stem) ][0]
    subj = [ f for f in subjdirs if f.split('./assignments/')[1].split('/')[0] == 'track'+str(stem) ][0]
    os.rename(subj,'./assignments/'+name)
    # os.rename(networks[i],'./networks/'+name)
    os.rename(track,name+'.tck')

    csv = [ f for f in csvs if f.split('./assignments/')[1].split('_')[0] == 'track'+str(stem) ]
    for j in csv:
        os.rename(j,'./assignments/'+name+'_'+j.split('_')[1])