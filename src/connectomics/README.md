# app-visual-white-matter

## polar angle meridians analysis
### Connectivity ecc x polar angle workflow:
1. generate eccentricity x polar angle parcellations
    - scripts:
        - parcellation-generator-main.sh
            - polar-angle-by-eccentricity-nifti-generator.sh
                - inputs:
                    - prfSurfacesDir
                    - prfVerticesDir
                    - min_degree_PA
                    - max_degree_PA
                    - min_degree_ECC
                    - max_degree_ECC
                    - freesurfer
                    - inputparc
                    - dwi
            - combine-parcellation.sh
                - inputs:
                    - min_degree_PA
                    - max_degree_PA
                    - min_degree_ECC
                    - max_degree_ECC
    - for now, hard-set ecc and polar angle bins (for meridian analysis)
        - polar angle: 0-20, 35-55, 80-100, 125-145, 160-180 (5)
        - eccentricity: 0-1, 1-2, 2-3, 3-4, 4-5, 5-6, 6-7, 7-8, 8-90 (9)
        - total number of parcellations: 45
    - for future, will want to be able to sweep across x degree sweeps
        - polar angle: +/- 10 degrees, +/- 20 degrees
        - eccentricity: +/- 1 degree
2. segment streamlines that connect within each ecc x polar angle parcellation
    - scripts:
        - tract-segmentation-main.sh
            - initial-tract-segment.sh
                - inputs:
                    - track
                    - both_endpoints
            - cleanup-assignments.py
            - final-tract-segment.sh
                - inputs:
                    - track
    - 45 total tractograms
3. generate connectivity matrices for each ecc x polar angle parcellation
    - scripts:
        - scmrt-connectivity-main.sh
            - extract-streamline-weights.py (skipping for now)
                - inputs:
                    - labels
                    - weights
                        - will only run if both labels & weights exist.
            - generate-connectomes.sh
                - inputs:
                    - varea_parc
                    - varea_label
                    - assignment_radial_search
                    - assignment_reverse_search
                    - assignment_forward_search
                    - length_vs_invlength
            - update-assignments.py
    - output as conmats
    - similarity measures (6 total)
        - count, length, inv length, density, den len, den inv len
4. generate network datatypes
    - scripts:
        - network-generator- main.sh
            - network-generator.py
    - one for each ecc x polar angle parcellation (45)
    - one for each similarity measure (6)
5. compute network measurements on each network datatype
    - scripts:
        - network-measurements-main.sh
            - network-measurements.py
                - inputs:
                    - richClubPercentage
            - clean-up-file-names.py
6. create cortexmap datatype
    - scripts:
        - cortexmap-generator-main.sh
            - cortex-mapping-pipeline.sh
7. create wmc datatype for all generated connectome tracts
    - scripts:
        - wmc-generator-main.sh
            - generate-wmc.py
            - parcellation2vtk.py
8. generate dataframes of network statistics
    - scripts:
        -netstats-generator-main.sh
            -generate-netstats.py

#### MAIN main order of scripts
1. parcellation-generator-main.sh
    - inputs in config for this section:
        - prfSurfacesDir
        - prfVerticesDir
        - min_degree_PA
        - max_degree_PA
        - min_degree_ECC
        - max_degree_ECC
        - freesurfer
        - inputparc
        - dwi
2. tract-segmentation-main.sh
    - inputs in config for this section:
        - track
        - both_endpoints
3. scmrt-connectivity-main.sh
    - inputs in config for this section:
        - varea_parc
        - varea_label
        - assignment_radial_search
        - assignment_reverse_search
        - assignment_forward_search
        - length_vs_invlength
        - not being used:
            - labels
            - weights
4. network-generator-main.sh
    - no configurable inputs. everything comes from previous scripts
5. network-measurements-main.sh
    - inputs in config for this section:
        - richClubPercentage
6. cortexmap-generator-main.sh
7. wmc-generator-main.sh
8. netstats-generator-main.sh

# config.json sample
```
{
    "prfSurfacesDir":   "input/prf/prf_surfaces",
    "prfVerticesDir":   "input/prf/prf_verts,
    "freesurfer":   "input/freesurfer/output",
    "inputparc":   "aparc.a2009s",
    "dwi":   "input/dwi/dwi.nii.gz",
    "track":   "input/track/track.tck",
    "varea_parc":   "input/varea/parc.nii.gz",
    "varea_label":   "input/varea/label.json",
    "min_degree_PA":   "0 35 80 125 160",
    "max_degree_PA":   "20 55 100 145 180",
    "min_degree_ECC":   "0 1 2 3 4 5 6 7 8",
    "max_degree_ECC":   "1 2 3 4 5 6 7 8 90",
    "both_endpoints":   "true",
    "assignment_radial_search":   4,
    "assignment_reverse_search":   "",
    "assignment_forward_search":   "",
    "length_vs_invlength":   "true",
    "labels":   "",
    "weights":   "",
    "richClubPercentage":   90,
    "analysis": "polarAngleMeridiansConnectomics",
    "_inputs": [
        {
            "meta": {
                "subject": "CC520287"
            }
        }
    ]
}
```

#### output datatypes
- neuro/conmats
- generic/networks
- neuro/parcellation/volume
- neuro/cortexmap
- neuro/track/tck
- neuro/tcks
- raw
- neuro/wmc
- neuro/net-stats

