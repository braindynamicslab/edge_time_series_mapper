# edge_time_series_mapper

This repository contains code accompanying the paper:

**Global topology of brain-wide co-fluctuations links task states, personality, and behavioral symptom dimensions**

Code will be fully available soon.

## Navigating the repo.

To gather all computational data, execute codes in `expt/` in the order specified by their filenames.

Refer to files in `config/` to locate directories, adapted to different setup (local machine v.s. high-performance-computing cluster).
`repo_root` refers to the path of the repo.
`scratch_directory` refers to the path on the cloud server that stores large-size computational data.

## Plots

Plots from computational results were aggregated in Powerpoint.
* Fig 1 is a conceptual figure with no computational data.
* Fig 2 consists of instances of Mapper graphs and the distributions of their quality of modularity.
  * The former is stored at `<scratch directory>/simplex_mapper_raw_features_cohort_one_LR_<simplex>_schaefer100x7/simplexMapper_<simplex>_100206_LR_schaefer100x7.pdf`, where `simplex` takes values `node`, `edge`, or `triangle`.
  * The latter is stored at `<repo_root>/data_pipeline/plot_modularity_comparison/plot_modularity_comparison_cohort_<cohort>_LR_coherence_schaefer100x7_with_sig.pdf`, where `cohort` takes values `one`, or `two`.
* Fig 3 consists of annotated Mapper graphs and the effect of shuffling on the quality of modularity.
  * The former is stored at 
  * The latter is stored at the following directory `<repo_root>/data_pipeline/plot_shuffled_modularity/` with the following filenames:
    * `shuffled_modularity_<cohort>_LR_<simplex>_all_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`; and `simplex` takes values `node`, `edge`, or `triangle`.
    * `delta_modularity_peak_dense_minus_none_<cohort>_LR_all_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`
    * `delta_modularity_peak_dense_minus_none_<cohort>_LR_all_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`
    * `within_task_centrality_<cohort>_LR_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`


