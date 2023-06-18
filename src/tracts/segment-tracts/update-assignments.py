#!/usr/bin/env python3

import os, sys
import pandas as pd
import numpy as np
import glob
import nibabel as nib
import json

# def load_parc_data(parc_file):

#     parc = nib.load(parc_file)
    
#     return parc.get_fdata()

def load_labels(label_filepath):

    return pd.read_json(label_filepath,orient='records')

def build_dictionary(keys,values):

    out_dictionary = dict(zip(keys,values))

    return out_dictionary

def build_labels_dictionary(labels):

    labels_dictionary = {}

    index = labels['label'].tolist()
    names = labels['name'].tolist()

    labels_dictionary = build_dictionary(index,names)
    
    return labels_dictionary

def update_assignments_csv(assignment,varea_labels,outpath,bname):

    # grab assignments file and rename columns for easier manipulation
    assignments = pd.read_csv(assignment,header=None,sep=" ")
    assignments.rename(columns={0: 'pair1', 1: 'pair2'},inplace=True)

    # flip pairs if pair1 > pair2
    mask = assignments['pair1'] > assignments['pair2']
    assignments.loc[mask,['pair1','pair2']] = assignments.loc[mask,['pair2','pair1']].values
    
    # identify unique node pairings from assignments. will exclude any instances where a streamline had a 0 assignment, meaning it did not connect nodes
    unique_edges_unclean = assignments.groupby(['pair1','pair2']).count().index.values
    
    #NEED TO ADDRESS SITUATION FOR LGN AND OPTIC CHIASM (25, 26, 27)
    if 'lgn' or 'optic-chiasm' in str(varea_labels['name'].tolist()):
        lgn_oc = varea_labels.loc[(varea_labels['name'].str.contains('lgn')) | (varea_labels['name'].str.contains('optic-chiasm'))].label.tolist()
    else:
        lgn_oc = []

    unique_edges = [ list(f) for f in unique_edges_unclean if (f[0] != 0 and f[1] == 0) or (f[1] != 0 and f[0] == 0) or (f[0] in lgn_oc) or (f[1] in lgn_oc)]
    # unique_names = [ str(f[0]) if f[0] != 0 else str(f[1]) for f in unique_edges ]
    unique_names = [ str(f[0])+'_'+str(f[1]) if f[0] in lgn_oc or f[1] in lgn_oc else str(f[0]) if f[0] != 0 else str(f[1]) for f in unique_edges ]
    # unique_names = list(np.unique([ f if '_' not in f else f.split('_')[1]+'_'+f.split('_')[0] if int(f.split('_')[1]) < int(f.split('_')[0]) else f for f in unique_names ])) # need to do this in cases where the lgn / oc are present and the order is flipped
    unique_indexes = [ f+1 for f in range(len(unique_names))]
    labels_dict = {unique_names[i]: str(unique_indexes[i]) for i in range(len(unique_names))}

    # create temporary column combining the roi pair names
    assignments['combined_name'] = [ str(assignments['pair1'][f])+'_'+str(assignments['pair2'][f]) if assignments['pair1'][f] in lgn_oc or assignments['pair2'][f] in lgn_oc else str(assignments['pair2'][f]) for f in range(len(assignments['pair1'])) ]
    
    # generate indexes for each streamline
    assignments['index'] = assignments["combined_name"].map(labels_dict)
    assignments['index'] = [ int(f) if f is not np.nan else 0 for f in assignments["index"] ]
    assignments.combined_name = np.where(assignments["index"].eq(0), "not-classified", assignments.combined_name)


    indices = assignments['index'].values.tolist()
    names = assignments['combined_name'].values.tolist()

    # set up output csvs
    out_index = pd.DataFrame(indices)
    out_names = pd.DataFrame(names)

    # output csv files
    out_index.to_csv(outpath+'/'+bname+'_index.csv',index=False,header=False)
    out_names.to_csv(outpath+'/'+bname+'_names.csv',index=False,header=False)

def main():

    with open('config.json','r') as config_f:
        config = json.load(config_f)

    # build varea labels and dictionary
    varea_label_file = config['varea_label']
    varea_labels = load_labels(varea_label_file)
    # varea_dict = build_labels_dictionary(varea_labels)

    assignments = [ f for f in glob.glob('./*assignments.csv') ]

    outdir = './assignments'

    if not os.path.isdir(outdir):
        os.mkdir(outdir)

    for assignment in assignments:
        bname = assignment.split('_assignments.csv')[0].split('./assignments/')[1]
        update_assignments_csv(assignment,varea_labels,outdir,bname)

if __name__ == '__main__':
    main()
