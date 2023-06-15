#!/usr/bin/env python3

import os
import json
import numpy as np
from scipy.io import loadmat
import glob
import pandas as pd

def write_txt(data,out_name):

	with open(out_name,'wt') as out_file:
		out_file.write('\n'.join(data))

def identify_both_endpoints(data,labels):
	
	return data.apply(lambda x: multi_label(x[0],x[1],labels), axis='columns').tolist()

def multi_label(x,y,labels):
	
    if x > 0:
        if x in labels.loc[labels['base'] == labels.loc[labels['label'] == x]['base'].values[0]]['label'].tolist() and y in labels.loc[labels['base'] == labels.loc[labels['label'] == x]['base'].values[0]]['label'].tolist():
            return x
        else:
            return 0
    else:
        return 0

def load_assignment_data(assignment):

	return pd.read_table(assignment,sep=" ",header=None,skiprows=1)

def load_labels(label_file):
	
    return pd.read_json(label_file,orient='records')

def main():

    # identify all assignments files
    assignments ='track_assignments.txt'
        
    tmp = load_assignment_data(assignments)

    labels = load_labels('./parc/label.json')
    labels['base'] = [ '.'.join(f.split('.')[1:]) if 'h.' in f else f for f in labels['name'] ]
    
    out_assignments = identify_both_endpoints(tmp,labels)

    write_txt([ str(f) for f in out_assignments],"assignments_both_endpoints.txt")

if __name__ == '__main__':
	main()
