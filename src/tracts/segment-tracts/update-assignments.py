#!/usr/bin/env python3

import os, sys
import pandas as pd
import numpy as np
import glob

def update_assignments_csv(assignment,outpath,bname):

    # grab assignments file and rename columns for easier manipulation
    assignments = pd.read_csv(assignment,header=None,sep=" ")
    assignments.rename(columns={0: 'pair1', 1: 'pair2'},inplace=True)

    # identify unique node pairings from assignments. will exclude any instances where a streamline had a 0 assignment, meaning it did not connect nodes
    unique_edges_unclean = assignments.groupby(['pair1','pair2']).count().index.values
    unique_edges = [ list(f) for f in unique_edges_unclean if (f[0] != 0 and f[1] == 0) or (f[1] != 0 and f[0] == 0)]
    unique_names = [ str(f[0]) if f[0] != 0 else str(f[1]) for f in unique_edges ]
    unique_indexes = [ f+1 for f in range(len(unique_edges))]
    labels_dict = {unique_names[i]: str(unique_indexes[i]) for i in range(len(unique_edges))}

    # create temporary column combining the roi pair names
    assignments['combined_name'] = [ str(assignments['pair1'][f]) if assignments['pair1'][f]>0 and assignments['pair2'][f]==0 else str(assignments['pair2'][f]) if assignments['pair2'][f]>0 and assignments['pair1'][f] == 0 else 0 for f in range(len(assignments['pair1'])) ]
    # assignments["combined_name"] = assignments['pair1'].astype(str) + "_" + assignments['pair2'].astype(str)

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

    assignments = [ f for f in glob.glob('./assignments/*assignments.csv') ]

    outdir = './assignments'

    if not os.path.isdir(outdir):
        os.mkdir(outdir)

    for assignment in assignments:
        bname = assignment.split('_assignments.csv')[0].split('./assignments/')[1]
        update_assignments_csv(assignment,outdir,bname)

if __name__ == '__main__':
    main()
