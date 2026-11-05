# Data

The data is not part of this repository. It is the official archive of the benchmark, published by
the authors of the paper:

> J. Weigand, J. Götz, J. Ulmen, M. Ruskowski, *Dataset and Baseline for an Industrial Robot
> Identification Benchmark*, TU Kaiserslautern, 2022. DOI: [10.26204/DATA/5](https://doi.org/10.26204/data/5)

License of the archive (as given on its page): MIT License, Creative Commons Attribution Share Alike 4.0 International.

## How to get it

1. Open https://doi.org/10.26204/data/5 and download `Robot_Identification_Benchmark_With_Raw_Data.rar.zip`.
   The other archive, "without raw data", is not enough: step 1 needs the raw recordings.
2. Unpack it. It is a `.rar` file inside a `.zip` file; 7-Zip can open both.
3. Put the folder `Robot_Identification_Benchmark_With_Raw_Data` here, so that this path exists:

```
data/Robot_Identification_Benchmark_With_Raw_Data/
├── raw_data/                                     12 recordings, recording_2021_12_15_*.mat (about 18 MB each)
├── forward_identification_without_raw_data.mat   the forward benchmark (torque -> position)
├── inverse_identification_without_raw_data.mat   the inverse benchmark (position, velocity, acceleration -> torque)
├── saved_linear_model/trained_model.mat          the version 1 models of the authors
├── MASTER_filter_and_combine_datasets.m          official post-processing script
├── MASTER_identification_linear.m                official baseline script (version 1)
└── visualization_functions/
```

The folder is about 222 MB. The scripts of this repository only read it and never change it
(step 1 runs the official script on a temporary copy).
