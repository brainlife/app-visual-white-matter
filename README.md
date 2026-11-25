# app-visual-white-matter

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

**Segments a tractogram into connections between visual areas of a visual-area parcellation with MRtrix3, and outputs the tracts, connectomes, networks and network statistics.**

Assigns streamline endpoints to the regions of the visual-area parcellation with tck2connectome, extracts the tracts connecting each pair of regions with connectome2tck, and builds count, density and length connectomes, networks and network measurements (cxnetwork) and statistics CSVs. Use it to study structural connections between visual areas once a visual-area parcellation exists in DWI space. Needs a tractogram and a visual-area parcellation of the same subject in the same space.

Run it on brainlife.io: [https://doi.org/10.25663/brainlife.app.840](https://doi.org/10.25663/brainlife.app.840)

| Input | Datatype | Required | Description |
|---|---|---|---|
| `track` | `neuro/track/tck` | yes | Whole-brain tractogram (.tck). |
| `varea` | `neuro/parcellation/volume` | yes | Visual-area volumetric parcellation with its label file. Must be in the same space as the tractogram. |

| Output | Datatype | Description |
|---|---|---|
| `track` | `neuro/track/tck` | Tractogram of the streamlines connecting visual areas. |
| `tracts` | `neuro/tcks` | One .tck file per pair of visual areas. |
| `connectomes` | `neuro/conmats` | Count, density and length connectivity matrices between visual areas. |
| `networks` | `generic/networks` | Networks built from the connectomes, with network measurements. |
| `net-stats` | `neuro/net-stats` | CSV tables of network statistics. |

| Parameter | Type | Default | Description |
|---|---|---|---|
| `analysis` | enum | `polarAngleMeridiansConnectomics` | Analysis pipeline to run; only polarAngleMeridiansConnectomics is implemented. Options: `polarAngleMeridiansConnectomics`. |
| `endpoints_assignment` | enum | `both_endpoints` | Must be both_endpoints, which builds connectomes, networks and network statistics between visual areas; other values skip those steps in this version. Options: `both_endpoints`, `single_endpoints`. |
| `assignment_radial_search` | number | `4` | Radial search distance passed to MRtrix3 tck2connectome -assignment_radial_search when assigning streamline endpoints to nodes (used only if different from 4). (mm) |
| `assignment_reverse_search` | string |  | Value for tck2connectome -assignment_reverse_search; leave blank to not use it. |
| `assignment_forward_search` | string |  | Value for tck2connectome -assignment_forward_search; leave blank to not use it. |
| `inv_length` | boolean | `true` |  |
| `richClubPercentage` | number | `90` | Percentile threshold used to compute the rich-club coefficient in the network measurements. |

Runtime: 8 CPUs; 3 h walltime.

<!-- brainlife-app:end -->

## potential analyses
1. polarAngleMeridiansConnectomics: this analysis pipeline will use structural connectivity within binned polar angle x eccentricity maps