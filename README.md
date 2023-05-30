# app-visual-white-matter

## polar angle meridians analysis
### Connectivity ecc x polar angle workflow:
1. generate eccentricity x polar angle parcellations
    -for now, hard-set ecc and polar angle bins (for meridian analysis)
        -polar angle: 0-20, 35-55, 80-100, 125-145, 160-180 (5)
        -eccentricity: 0-1, 1-2, 2-3, 3-4, 4-5, 5-6, 6-7, 7-8, 8-90 (9)
        -total number of parcellations: 45
    -for future, will want to be able to sweep across x degree sweeps
        -polar angle: +/- 10 degrees, +/- 20 degrees
        -eccentricity: +/- 1 degree
2. segment streamlines that connect within each ecc x polar angle parcellation
    -45 total tractograms
3. generate connectivity matrices for each ecc x polar angle parcellation
    -output as conmats
    -similarity measures (6 total)
        -count, length, inv length, density, den len, den inv len
4. generate network datatypes
    -one for each ecc x polar angle parcellation (45)
    -one for each similarity measure (6)
5. compute network measurements on each network datatype

#### counts of output datatypes
parcellations: 45 (1 giant parcellation)
track/tck: 45 (1 giant tractogram)
conmats: 275 (45 tractograms x 6 similarity measures)
networks: 550 (275 x 2; one for network, one for measurements)


