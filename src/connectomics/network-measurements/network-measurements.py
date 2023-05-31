#!/usr/bin/env python

import sys
import os.path
from os.path import join as PJ
import re
import json
import numpy as np
from tqdm import tqdm
import igraph as ig
import jgf

import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt



def calcModularity(g):
	if("Community" in g.vertex_attributes()):
		Ci = reindexList(g.vs["Community"])
	else:
		return (None,None)
	if("weight" in g.edge_attributes()):
		return None, g.modularity(Ci, weights="weight");
	else:
		return None, g.modularity(Ci, weights=None);



def calcDegree(g):
	results = np.array(g.degree(mode="ALL"))
	return results, np.average(results)


def calcInDegree(g):
	if(not g.is_directed()):
		return (None,None)
	results = np.array(g.indegree())
	return results, np.average(results)

def calcOutDegree(g):
	if(not g.is_directed()):
		return (None,None)
	results = np.array(g.outdegree())
	return results, np.average(results)

def calcStrength(g):
	if("weight" not in g.edge_attributes()):
		return (None,None)
	results = np.array(g.strength(mode="ALL", weights = "weight"))
	return results, np.average(results)

def calcInStrength(g):
	if("weight" not in g.edge_attributes() or not g.is_directed()):
		return (None,None)
	results = np.array(g.strength(mode="IN", weights = "weight"))
	return results, np.average(results)

def calcOutStrength(g):
	if("weight" not in g.edge_attributes() or not g.is_directed()):
		return (None,None)
	results = np.array(g.strength(mode="OUT", weights = "weight"))
	return results, np.average(results)

def calcClusteringCoefficient(g):
	# if("weight" in g.edge_attributes()):
	results = g.transitivity_local_undirected(weights=None)
	# else:
	# 	results = g.transitivity_local_undirected(weights="weight")
	return np.nan_to_num(results,0), np.nanmean(results)

def calcCoreness(g):
	results = np.array(g.coreness(mode="ALL"))
	return results, None

def calcMatchIndex(g):
	degree = np.array(g.degree())
	matchIndex = np.zeros(g.ecount())
	for id,e in enumerate(g.es):
		node1,node2 = e.tuple
		viz1 = g.neighbors(node1)
		viz2 = g.neighbors(node2)
		sharedNei = set(viz1) & set(viz2)
		if ((degree[node1]+degree[node2]) > 2):
			matchIndex[id] = len(sharedNei)/float(degree[node1]+degree[node2]-2)
		else:
			matchIndex[id] = 0
	meanMatchIndex = np.mean(matchIndex)
	return None, meanMatchIndex

def calcBetweenessCentrality(g):
	result = np.array(g.betweenness(directed=g.is_directed()))
	return result,np.average(result)

def calcBetweenessCentralityWeighted(g):
	if("weight" not in g.edge_attributes()):
		return (None,None)
	result = np.array(g.betweenness(weights="weight"))
	return result,np.average(result)

def calcBetweennessCentralization(G):
	vnum = G.vcount()
	if vnum < 3:
		return None,0
	denom = (vnum-1)*(vnum-2)
	temparr = [2*i/denom for i in G.betweenness()]
	max_temparr = max(temparr)
	return None,sum(max_temparr-i for i in temparr)/(vnum-1)

def calcRichClubCoefficient(g, highest=True, scores=None, indices_only=False):
	Trc = richClubPercentage
	degree = np.array(g.degree())
	edges = np.array(g.get_edgelist())
	sourceDegree,targetDegree = degree[edges[:,0]],degree[edges[:,1]]
	dT = int(np.percentile(degree,Trc))
	indNodes = np.nonzero(degree>=dT)[0]
	indEdges = np.nonzero((sourceDegree>=dT)&(targetDegree>=dT))[0]
	if (indNodes.size>1):
		RC = 2.*indEdges.size/(indNodes.size*(indNodes.size-1))
	else:
		RC = 0
	return None,RC

def calcDegreeAssortativity(g):
	return None,g.assortativity_degree(directed=g.is_directed())

def calcDiameter(g):
	if("weight" in g.edge_attributes()):
		return None,g.diameter(directed=g.is_directed(),weights="weight")
	else:
		return None,g.diameter(directed=g.is_directed())

def reindexList(names,returnDict=False):
	d = {ni: indi for indi, ni in enumerate(set(names))}
	numbers = [d[ni] for ni in names]
	if(returnDict):
		return numbers,d
	else:
		return numbers

def getNeighborhoods(g,mode="ALL"):
	if("weight" in g.edge_attributes()):
		return [[(e.target,e["weight"]) if e.target!=i else (e.source,e["weight"]) for e in g.es[g.incident(i,mode=mode)]] for i in range(g.vcount())]
	else:
		return [[(e.target,1) if e.target!=i else (e.source,1) for e in g.es[g.incident(i,mode=mode)]] for i in range(g.vcount())]

def calcModuleDegreeZScore(g,mode="ALL"):
	if("Community" in g.vertex_attributes()):
		Ci = reindexList(g.vs["Community"])
	else:
		return (None,None)
	neighs = getNeighborhoods(g,mode=mode)
	cneighs = [[(Ci[vertexID],weigth) for vertexID,weigth in neigh] for neigh in neighs]
	kappa = np.zeros(g.vcount())
	kappaSi = [[] for _ in range(max(Ci)+1)]
	
	for i in range(g.vcount()):
		kappa[i] = np.sum([weight for community,weight in cneighs[i] if community==Ci[i]])
		kappaSi[Ci[i]].append(kappa[i])

	avgKappaSi = np.zeros(max(Ci)+1)
	stdKappaSi = np.zeros(max(Ci)+1)

	for ci in range(len(kappaSi)):
		avgKappaSi[ci] = np.average(kappaSi[ci])
		stdKappaSi[ci] = np.std(kappaSi[ci])
	
	zmodule = np.zeros(g.vcount())
	for i in range(g.vcount()):
		ci = Ci[i]
		if(stdKappaSi[ci]>0):
			zmodule[i] = (kappa[i]-avgKappaSi[ci])/stdKappaSi[ci]
	return zmodule,None


def calcParticipationCoeff(g,mode="ALL"):
	if("Community" in g.vertex_attributes()):
		Ci = reindexList(g.vs["Community"])
	else:
		return (None,None)
	neighs = getNeighborhoods(g,mode=mode)
	cneighs = [[(Ci[vertexID],weigth) for vertexID,weigth in neigh] for neigh in neighs]
	
	if("weight" in g.edge_attributes()):
		degrees = np.array(g.strength(mode=mode,weights="weight"))
	else:
		degrees = np.array(g.degree(mode=mode))

	kappasi = np.zeros(g.vcount())
	for i in range(g.vcount()):
		nodeCommunities = set([community for community,weight in cneighs[i]])
		communityDegrees = {community:0 for community in nodeCommunities}
		for community,weight in cneighs[i]:
			communityDegrees[community]+=weight
		kappasi[i] = np.sum(np.power(list(communityDegrees.values()),2))
	
	result = 1.0-kappasi/np.power(degrees,2.0)
	result[degrees==0.0] = 0
	return result,None


measurements = {
	"Degree" : calcDegree,
	"InDegree" : calcInDegree,
	"OutDegree" : calcOutDegree,
	"Strength" : calcStrength,
	"InStrength" : calcInStrength,
	"OutStrength" : calcOutStrength,
	"ClusteringCoefficient" : calcClusteringCoefficient,
	"Coreness" : calcCoreness,
	"MatchIndex" : calcMatchIndex,
	"BetweenessCentrality" : calcBetweenessCentrality,
	"BetweenessCentralityWeighted" : calcBetweenessCentralityWeighted,
	"BetweennessCentralization" : calcBetweennessCentralization,
	"RichClubCoefficient" : calcRichClubCoefficient,
	"DegreeAssortativity" : calcDegreeAssortativity,
	"Diameter" : calcDiameter,
	"ModuleDegreeZScore" : calcModuleDegreeZScore,
	"ParticipationCoeff" : calcParticipationCoeff,
	"Modularity" : calcModularity,
}


def isFloat(value):
	if(value is None):
		return False
	try:
		numericValue = float(value)
		return np.isfinite(numericValue)
	except ValueError:
		return False


class NumpyEncoder(json.JSONEncoder):
	def default(self, obj):
		if isinstance(obj, (np.int_, np.intc, np.intp, np.int8,
			np.int16, np.int32, np.int64, np.uint8,
			np.uint16, np.uint32, np.uint64)):
			ret = int(obj)
		elif isinstance(obj, (np.float_, np.float16, np.float32, np.float64)):
			ret = float(obj)
		elif isinstance(obj, (np.ndarray,)): 
			ret = obj.tolist()
		else:
			ret = json.JSONEncoder.default(self, obj)

		if isinstance(ret, (float)):
			if math.isnan(ret):
				ret = None

		if isinstance(ret, (bytes, bytearray)):
			ret = ret.decode("utf-8")

		return ret

results = {"errors": [], "warnings": [], "brainlife": [], "datatype_tags": [], "tags": []}

def warning(msg):
	global results
	results['warnings'].append(msg) 
	#results['brainlife'].append({"type": "warning", "msg": msg}) 
	print(msg)

def error(msg):
	global results
	results['errors'].append(msg) 
	#results['brainlife'].append({"type": "error", "msg": msg}) 
	print(msg)

def exitApp():
	global results
	with open("product.json", "w") as fp:
		json.dump(results, fp, cls=NumpyEncoder)
	if len(results["errors"]) > 0:
		sys.exit(1)
	else:
		sys.exit()

def exitAppWithError(msg):
	global results
	results['errors'].append(msg) 
	#results['brainlife'].append({"type": "error", "msg": msg}) 
	print(msg)
	exitApp()







# configFilename = "config.json"
# argCount = len(sys.argv)
# if(argCount > 1):
configFilename = sys.argv[1]

outputDirectory = sys.argv[2]
outputFile = PJ(outputDirectory,"network.json.gz")

if(not os.path.exists(outputDirectory)):
		os.makedirs(outputDirectory)

with open(configFilename, "r") as fd:
		config = json.load(fd)


# "transform":"absolute", //"absolute" or "signed"
# "retain-weights":false,
# "threshold": "none"

richClubPercentage = 90

if("richClubPercentage" in config):
	richClubPercentage = int(config["richClubPercentage"]);


aM = jgf.conmat.load(config['network'],compressed=True)
if not np.isnan(aM[0][0][0]):
	networks = jgf.igraph.load(config["network"], compressed=True)

	outputNetworks = []

	for network in tqdm(networks):
		
		weighted = "weight" in network.edge_attributes()
		hasCommunities = "Community" in network.vertex_attributes()
		
		for measurement,measurementFunction in measurements.items():
			nodePropData,networkPropData = measurementFunction(network)
			

			if(nodePropData is not None):
				network.vs[measurement] = nodePropData

			if(networkPropData is not None):
				if(nodePropData is not None): #Average measurement
					network["Avg. "+measurement] = networkPropData
				else:
					network[measurement] = networkPropData
			
		outputNetworks.append(network)

	jgf.igraph.save(outputNetworks, outputFile, compressed=True)
else:
	print('empty matrix')

exitApp()
