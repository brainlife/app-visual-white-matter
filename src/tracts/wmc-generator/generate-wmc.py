#!/usr/bin/env python3

import glob
import os,sys
import pandas as pd
import numpy as np
import json
import nibabel as nib
from dipy.io.streamline import load_tractogram
import scipy.io as sio
from matplotlib import cm

def load_parcel_volume(parcel_volume_file,names):

    data = pd.read_csv(parcel_volume_file,header=None)
    data = data.rename(columns={0: "volume"})
    data['index'] = names

    return data

def build_tractmeasures_df(parcel_volume_dict,names_df,subjectID,outpath):

    tractmeasures_df = pd.DataFrame()
    tractmeasures_df['structureID'] = names_df['tract_name'].unique().tolist()
    tractmeasures_df['subjectID'] = [ subjectID for f in tractmeasures_df['structureID'] ]
    tractmeasures_df['parcel'] = [ '.'.join(f.split('-')[-2:]) for f in tractmeasures_df['structureID'] ]
    tractmeasures_df['count'] = [ len(names_df.loc[names_df['tract_name'] == f]) for f in tractmeasures_df['structureID'] ]
    tractmeasures_df['parcel_density'] = tractmeasures_df['parcel'].map(parcel_volume_dict)
    tractmeasures_df['density'] = tractmeasures_df['count'] / tractmeasures_df['parcel_density']
    tractmeasures_df = tractmeasures_df.drop(columns=['parcel','parcel_density'])

    if outpath:
        tractmeasures_df.to_csv(outpath+'/tractmeasures.csv',index=False)

    return tractmeasures_df

def identify_track_order(track_info_path):

    with open(track_info_path,'r') as txt_f:
        track_info = txt_f.readlines()

    tmp = [ f for f in track_info if 'tckedit' in f][0].split(" ")

    track_order = [ f.replace('.tck','') for f in tmp if ".tck" in f][:-1]

    return track_order

def load_index_names(file_path):

    return pd.read_csv(file_path,header=None)

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

def build_wmc_classification(df,track):

    bundle_names = df['tract_name'].unique().tolist()
    names = np.array(bundle_names,dtype=object)

    # generate tracts
    colors = np.reshape([np.random.random(len(bundle_names)).tolist(),np.random.random(len(bundle_names)).tolist(),np.random.random(len(bundle_names)).tolist()],(len(bundle_names),3)).tolist()
    
    streamline_index = np.zeros(len(track.streamlines))
    tractsfile = []

    for bnames in range(np.size(bundle_names)):
        tract_ind = df.loc[df['tract_name'] == bundle_names[bnames]]['stream_index'].index.tolist()
        streamline_index[tract_ind] = df.loc[df['tract_name'] == bundle_names[bnames]]['stream_index'].unique()[0]
        streamlines = np.zeros([len(track.streamlines[tract_ind])],dtype=object)
        for e in range(len(streamlines)):
            streamlines[e] = np.transpose(track.streamlines[tract_ind][e]).round(2)

        color=colors[bnames]
        count = len(streamlines)

        jsonfibers = np.reshape(streamlines[:count], [count,1]).tolist()
        for i in range(count):
            jsonfibers[i] = [jsonfibers[i][0].tolist()]

        with open ('wmc/tracts/'+str(df.loc[df['tract_name'] == bundle_names[bnames]]['stream_index'].unique()[0])+'.json', 'w') as outfile:
            jsonfile = {'name': bundle_names[bnames], 'color': color, 'coords': jsonfibers}
            json.dump(jsonfile, outfile)

        tractsfile.append({"name": bundle_names[bnames], "color": color, "filename": str(df.loc[df['tract_name'] == bundle_names[bnames]]['stream_index'].unique()[0])+'.json'})

    with open ('wmc/tracts/tracts.json', 'w') as outfile:
        json.dump(tractsfile, outfile, separators=(',', ': '), indent=4)

    # save classification structure
    # sio.savemat('wmc/classification.mat', { "classification": {"names": np.reshape(names,(len(names),1)), "index": np.reshape(streamline_index,(len(streamline_index),1)) }})
    sio.savemat('wmc/classification.mat', { "classification": {"names": names, "index": streamline_index }})

    return bundle_names, streamline_index

def main():

    with open('config.json','r') as config_f:
        config = json.load(config_f)

    subjectID = config['_inputs'][0]['meta']['subject']

    # parseable configs needed and load
    dwi = nib.load(config['dwi'])
    tractogram = load_tractogram('./track/track.tck',dwi,bbox_valid_check=False)

    # make output directories
    if not os.path.isdir('wmc'):
        os.mkdir('wmc')
        os.mkdir('wmc/tracts')
    outdir='wmc'

    if not os.path.isdir('tractmeasures'):
        os.mkdir('tractmeasures')
    tmout='tractmeasures'

    # build varea labels and dictionary
    varea_label_file = config['varea_label']
    varea_labels = load_labels(varea_label_file)
    varea_dict = build_labels_dictionary(varea_labels)

    # build polar angle x eccentricity labels and dictionary
    polarEcc_label_file = './parc/label.json'
    polarEcc_labels = load_labels(polarEcc_label_file)
    polarEcc_labels['label'] = ['track'+str(f) for f in polarEcc_labels['label'] ]
    polarEcc_dict = build_labels_dictionary(polarEcc_labels)
    
    # identify track order in which the final tractogram was built
    track_order = identify_track_order('./track/track_info.txt')

    # identify all index and names files from assignments directory and build dataframe. sort by track order so the final wmc structure is in proper order
    index_files = glob.glob('./assignments/track*_index.csv')
    names_files = glob.glob('./assignments/track*_names.csv')
    index_names_df = pd.DataFrame(columns=['index','name','base'])
    index_names_df['index'] = sorted(index_files)
    index_names_df['name'] = sorted(names_files)
    index_names_df['base'] = [ f.split('./assignments/')[1].split('_names.csv')[0] for f in index_names_df['name'] ]
    index_names_df = index_names_df.sort_values(by="base", key=lambda column: column.map(lambda e: track_order.index(e))).reset_index(drop=True)

    # build a wmc dataframe to make things easier
    names_df = pd.DataFrame()
    for i in range(len(index_names_df['index'])):
        tmp = load_index_names(index_names_df['name'][i])
        tmp = tmp.rename(columns={0: 'parcels'})
        tmp['parcellation'] = [ index_names_df['base'][i] for f in tmp['parcels'] ]
        names_df = pd.concat([names_df,tmp])

    # reset index
    names_df = names_df.reset_index(drop=True)

    # sort parcels so everything is consistent. otherwise you'll have the same pairings, reverse order (i.e 1_3, 3_1) despite being the same connections
    # names_df['parcels'] =  [ f if int(f.split('_')[0])<int(f.split('_')[1]) else f.split('_')[1]+'_'+f.split('_')[0] for f in names_df['parcels'] ]

    # make individual pairs columns to make mapping easier
    # names_df['pair1'] = [ int(f.split('_')[0]) for f in names_df['parcels'] ]
    # names_df['pair2'] = [ int(f.split('_')[1]) for f in names_df['parcels'] ]

    # map varea parcels to each pair column
    # names_df['pair1'] = names_df['pair1'].map(varea_dict)
    # names_df['pair2'] = names_df['pair2'].map(varea_dict)
    names_df['parcels'] = names_df['parcels'].map(varea_dict)

    # map polar angle x eccentricity names to parcellation name
    names_df['parcellation'] = names_df['parcellation'].map(polarEcc_dict)

    # generate a name for the final wmc
    names_df['tract_name'] = names_df.apply(lambda x: x['parcellation'].replace('.','-')+'_'+x['parcels'],axis=1)

    # identify unique names and build wmc dictionary so we can add index values
    unique_parcels = names_df['tract_name'].unique().tolist()
    unique_indices = [ f+1 for f in range(len(unique_parcels)) ]
    wmc_dict = build_dictionary(unique_parcels,unique_indices)

    # set index
    names_df['stream_index'] = names_df['tract_name'].map(wmc_dict)

    # build final wmc structure
    bundle_names, streamline_index = build_wmc_classification(names_df,tractogram)

    # build tractmeasures dataframe
    parcel_volume = load_parcel_volume('parcel_volume.txt',varea_labels['name'].tolist())
    parcel_volume_dict = build_dictionary(parcel_volume['index'].tolist(),parcel_volume['volume'].tolist())
    tractmeasures_df = build_tractmeasures_df(parcel_volume_dict,names_df,subjectID,tmout)

if __name__ == "__main__":
    main()
    