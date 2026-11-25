<h1 align="center">Visual white matter connectomics</h1>

<p align="center">
  Tracts, connectomes, networks and network statistics of the structural connections between visual areas, or between polar-angle by eccentricity regions of the visual field, with MRtrix3.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.840"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.840-blue.svg" alt="Run on brainlife.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="MIT license"></a>
</p>

## At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Segments a tractogram into connections between visual areas of a visual-area parcellation with MRtrix3, and outputs the tracts, connectomes, networks and network statistics.**

Assigns streamline endpoints to the regions of the visual-area parcellation with tck2connectome, extracts the tracts connecting each pair of regions with connectome2tck, and builds count, density and length connectomes, networks and network measurements (cxnetwork) and statistics CSVs. Use it to study structural connections between visual areas once a visual-area parcellation exists in DWI space. Needs a tractogram and a visual-area parcellation of the same subject in the same space.

| | |
|---|---|
| **Inputs** | `neuro/track/tck` · `neuro/parcellation/volume` |
| **Outputs** | `neuro/track/tck` · `neuro/tcks` · `neuro/conmats` · `generic/networks` · `neuro/net-stats` |
| **Resources** | 8 CPUs · 3 h walltime |
| **Run it** | [doi.org/10.25663/brainlife.app.840](https://doi.org/10.25663/brainlife.app.840) |

#### Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `track` | `neuro/track/tck` | yes | Whole-brain tractogram (.tck). |
| `varea` | `neuro/parcellation/volume` | yes | Visual-area volumetric parcellation with its label file. Must be in the same space as the tractogram. |

#### Outputs

| Output | Datatype | Description |
|---|---|---|
| `track` | `neuro/track/tck` | Tractogram of the streamlines connecting visual areas. |
| `tracts` | `neuro/tcks` | One .tck file per pair of visual areas. |
| `connectomes` | `neuro/conmats` | Count, density and length connectivity matrices between visual areas. |
| `networks` | `generic/networks` | Networks built from the connectomes, with network measurements. |
| `net-stats` | `neuro/net-stats` | CSV tables of network statistics. |

<details>
<summary><b>Parameters</b> (7)</summary>

| Parameter | Type | Default | Description |
|---|---|---|---|
| `analysis` | enum | `polarAngleMeridiansConnectomics` | Analysis pipeline to run; only polarAngleMeridiansConnectomics is implemented. Options: `polarAngleMeridiansConnectomics`. |
| `endpoints_assignment` | enum | `both_endpoints` | Must be both_endpoints, which builds connectomes, networks and network statistics between visual areas; other values skip those steps in this version. Options: `both_endpoints`, `single_endpoints`. |
| `assignment_radial_search` | number | `4` | Radial search distance passed to MRtrix3 tck2connectome -assignment_radial_search when assigning streamline endpoints to nodes (used only if different from 4). (mm) |
| `assignment_reverse_search` | string |  | Value for tck2connectome -assignment_reverse_search; leave blank to not use it. |
| `assignment_forward_search` | string |  | Value for tck2connectome -assignment_forward_search; leave blank to not use it. |
| `inv_length` | boolean | `true` |  |
| `richClubPercentage` | number | `90` | Percentile threshold used to compute the rich-club coefficient in the network measurements. |

</details>

<!-- brainlife-app:end -->

## Versions on brainlife.io

This repository hosts two Apps, each built from its own branch. Both run the `polarAngleMeridiansConnectomics` analysis pipeline; they differ in the regions they connect.

| App | Regions | Branch | Run it | Status |
|---|---|---|---|---|
| Segment structural connections across visual areas | the visual areas of a parcellation you provide | [`v1.2`](https://github.com/brainlife/app-visual-white-matter/tree/v1.2) | [doi:10.25663/brainlife.app.840](https://doi.org/10.25663/brainlife.app.840) | current |
| Visual areas structural connections by eccentricity and polar angle | polar-angle by eccentricity regions built from pRF maps | [`v1.1`](https://github.com/brainlife/app-visual-white-matter/tree/v1.1) | [doi:10.25663/brainlife.app.784](https://doi.org/10.25663/brainlife.app.784) | available |

## Running the App

### On brainlife.io

**Across visual areas** ([doi.org/10.25663/brainlife.app.840](https://doi.org/10.25663/brainlife.app.840)): choose a whole-brain tractogram (`neuro/track/tck`) and a visual-area volumetric parcellation (`neuro/parcellation/volume`) of the same subject in the same space, and press **Execute**. Keep `endpoints_assignment` at `both_endpoints`; other values skip the connectome, network and statistics steps in this version.

**By eccentricity and polar angle** ([doi.org/10.25663/brainlife.app.784](https://doi.org/10.25663/brainlife.app.784)): also give the subject's DWI, FreeSurfer output and pRF results (`neuro/prf`). The App builds wedge-by-eccentricity regions from the pRF polar-angle and eccentricity maps on the FreeSurfer surface, projects them into DWI space and combines them with the visual-area parcellation and a FreeSurfer parcellation (`inputparc`). The regions are set by:

- `paMeridians`: polar-angle meridians at which the wedges are centred (default `0 45 90 135 180`);
- `paAngle`: half-width of each wedge around its meridian (default 15);
- `eccAngle`: width of each eccentricity bin from 0 to 8 degrees (default 2);
- `include_periph`: also add a peripheral bin from 8 to 90 degrees (default true).

In both Apps, streamline endpoints are assigned to regions with `tck2connectome` (`assignment_radial_search`, default 4 mm; `assignment_reverse_search` and `assignment_forward_search` are passed only when set), the tracts connecting each pair of regions are extracted with `connectome2tck`, and count, density, length and density-by-length connectomes are built. Networks and network measurements (`richClubPercentage`, default 90) are computed with cxnetwork.

### Locally

You need [Singularity/Apptainer](https://apptainer.org/) and [`jq`](https://jqlang.github.io/jq/). Each step runs in its own container, among them `brainlife/mrtrix3:3.0.0` and `3.0.3`, `brainlife/dipy:1.4.0`, `filsilva/cxnetwork:0.2.0` and `brainlife/ga-python:lab328-dipy141-pybrainlife-1.0`; v1.1 also uses FSL 5.0.11, Connectome Workbench and VTK containers.

1. Clone this repository and check out the App branch: `git checkout v1.2` (or `v1.1`).
2. Create `config.json`. For v1.2:

   ```json
   {
       "track": "input/track/track.tck",
       "varea_parc": "input/varea/parc.nii.gz",
       "varea_label": "input/varea/label.json",
       "analysis": "polarAngleMeridiansConnectomics",
       "endpoints_assignment": "both_endpoints",
       "assignment_radial_search": 4,
       "assignment_reverse_search": "",
       "assignment_forward_search": "",
       "richClubPercentage": 90
   }
   ```

   For v1.1, add `dwi`, `bvals`, `bvecs`, `freesurfer`, `prfSurfacesDir`, `prfVerticesDir`, `inputparc`, `paMeridians`, `paAngle`, `eccAngle` and `include_periph`. `src/connectomics/README.md` describes each step of the pipeline and the keys it reads.

3. Run the App:

   ```bash
   ./main
   ```

## Outputs

```text
track/track.tck         streamlines connecting the regions
tracts/tcks/            one .tck file per pair of regions
connectomes/track/      count_out, density_out, length_out and denlen_out connectivity matrices
networks/track/         one network per measure, with measurements/
net-stats/net-stats/    conmats.csv, global_measures.csv and local_measures.csv
assignments/            streamline-to-region assignments
```

The polar-angle by eccentricity App also writes the region parcellation in DWI space, a cortexmap of the surface regions and a white matter classification (`wmc`) of the region-to-region tracts.

## Troubleshooting

- **Length scaling**: the code reads the key `inverse_length` to choose between length and inverse-length scaling, while the App's option is called `inv_length`. When `inverse_length` is not set, the length and density-by-length connectomes are scaled by inverse length (`-scale_invlength`).
- **No connectomes or networks**: check that `endpoints_assignment` is `both_endpoints`.

## Citing

> [!TIP]
> If you use this App in your work, please cite the App, the software it builds on and brainlife.io (below). GitHub's **Cite this repository** button gives the App citation in APA and BibTeX.

- Segment structural connections across visual areas. brainlife.io App. [doi:10.25663/brainlife.app.840](https://doi.org/10.25663/brainlife.app.840)
- Fischl. FreeSurfer. *NeuroImage* 62:774-781 (2012). [doi:10.1016/j.neuroimage.2012.01.021](https://doi.org/10.1016/j.neuroimage.2012.01.021)
- Jenkinson et al. FSL. *NeuroImage* 62:782-790 (2012). [doi:10.1016/j.neuroimage.2011.09.015](https://doi.org/10.1016/j.neuroimage.2011.09.015)
- Tournier et al. MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation. *NeuroImage* 202:116137 (2019). [doi:10.1016/j.neuroimage.2019.116137](https://doi.org/10.1016/j.neuroimage.2019.116137)
- Garyfallidis et al. Dipy, a library for the analysis of diffusion MRI data. *Frontiers in Neuroinformatics* 8 (2014). [doi:10.3389/fninf.2014.00008](https://doi.org/10.3389/fninf.2014.00008)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. *Scientific Data* 6:69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

## Authors

- Brad Caron
- Junbeom Kwon

## Funding

[![Wellcome-226486/Z/22/Z](https://img.shields.io/badge/Wellcome-226486%2FZ%2F22%2FZ-purple.svg)](https://wellcome.org/)
[![NIH-NINDS-U24NS140384](https://img.shields.io/badge/NIH_NINDS-U24NS140384-green.svg)](https://reporter.nih.gov/project-details/11261037)
[![NIH-NINDS-UM1NS132207](https://img.shields.io/badge/NIH_NINDS-UM1NS132207-green.svg)](https://reporter.nih.gov/project-details/11411328)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://reporter.nih.gov/project-details/10262925)
[![NIH-NIBIB-R01EB030896](https://img.shields.io/badge/NIH_NIBIB-R01EB030896-green.svg)](https://reporter.nih.gov/project-details/10428625)
[![NIH-NIMH-R01MH126699](https://img.shields.io/badge/NIH_NIMH-R01MH126699-green.svg)](https://reporter.nih.gov/project-details/10460628)
[![NIH-NIDCD-R01DC020088](https://img.shields.io/badge/NIH_NIDCD-R01DC020088-green.svg)](https://reporter.nih.gov/project-details/11140284)
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-2203524](https://img.shields.io/badge/NSF_BCS-2203524-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2203524)
[![NSF-IIS-1636893](https://img.shields.io/badge/NSF_IIS-1636893-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-OAC-2148729](https://img.shields.io/badge/NSF_OAC-2148729-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148729)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NSF-IIS-2148700](https://img.shields.io/badge/NSF_IIS-2148700-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148700)
[![NSF-OAC-1916518](https://img.shields.io/badge/NSF_OAC-1916518-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1916518)

<sub>brainlife.io is publicly funded, and acknowledging that support helps keep it running. This App was developed with support from Wellcome, the U.S. National Institutes of Health (including the BRAIN Initiative BRAIN CONNECTS program: The Axonal Projectome EXchange, U24NS140384, and the Center for Mesoscale Connectomics, UM1NS132207) and the U.S. National Science Foundation.</sub>

## License

MIT.
