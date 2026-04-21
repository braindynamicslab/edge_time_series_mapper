# edge_time_series_mapper

This repository contains code accompanying the paper:

**Global topology of brain-wide co-fluctuations links task states, personality, and behavioral symptom dimensions**

Code will be fully available soon.

## Navigating the repo.

To gather all computational data, execute codes in `expt/` in the order specified by their filenames. Output data is stored in `data_pipeline`.

Refer to files in `config/` to locate directories, adapted to different setup (local machine v.s. high-performance-computing cluster).
`repo_root` refers to the path of the repo.
`scratch_directory` refers to the path on the cloud server that stores large-size computational data.

## Experiments

* Experiments are stored in `expt/`, and their scripts are labeled 00, 01a, 01b, ..., 02a, 02b, ... Scripts within the same experiments are to be run sequentially.

* Experiment 0 sets up the environment and processes the fMRI data structure.

* Experiment 1 computes the quality of modularity of node, edge, and triangle time series Mapper graphs with and without feature processing with different parameters (e.g. session, parcellation). It also computes a number of other summary statistics of these Mapper graphs.

* Experiments 0 and 1 must be run prior to the experiments below.

* Experiment 2 generates figures and statistics regarding the quality of modularity computed in Experiment 1. Its results are Fig 2 and Tables S1-2.

* Experiment 3 shuffles task labels in Mapper graphs to investigate the role of peak-dense pure nodes. Its results are Fig 3 and Tables S3, S6, and S7.

* Experiment 4 investigates the centrality of peak-dense pure nodes. Its results are the remainder of Fig 3 and Tables S4, S5, and S8.

* Experiment 5 investigates the correlation between the quality of modularity and personality, and behavioral symptoms. Its reuslts are figure 6 and Tables S10-12.

* Experiment 6 plots several instances of Mapper graphs. Its results are the Mapper graphs in Fig 2 and 3.

* Experiment 7 investigates different notions of high-amplitude functional connectivity. Its results are Fig 4 and Tables S9.

* Experiment 8 investigates the quadratic relationship between the node distace and edge distance. Its result is Fig 5.

* Experiment 9 investigates the stability of the quality of modularity across scans. Its result is Fig S13.

## Plots

Plots from computational results were aggregated in Powerpoint. Polished figures are stored in `<repo_root>/fig_polished`. Their ingredients are as follows.
* Fig 1 is a conceptual figure with no computational data.
* Fig 2 consists of instances of Mapper graphs and the distributions of their quality of modularity.
  * The former is stored at `<scratch directory>/simplex_mapper_raw_features_cohort_one_LR_<simplex>_schaefer100x7/simplexMapper_<simplex>_100206_LR_schaefer100x7.pdf`, where `simplex` takes values `node`, `edge`, or `triangle`.
  * The latter is stored at `<repo_root>/data_pipeline/plot_modularity_comparison/plot_modularity_comparison_cohort_<cohort>_LR_raw_features_schaefer100x7_with_sig.pdf`, where `cohort` takes values `one`, or `two`.
* Fig 3 consists of annotated Mapper graphs and the effect of shuffling on the quality of modularity.
  * The former is stored at `<repo_root>/data_pipeline/individual_mapper/simplex_mapper_edge_<subject>_LR_shaefer100x7_<filename suffix>.pdf`, where `subject` takes values 100206, 125525, 144832, 192641, 725751; `filename suffix` takes values `peak_density_colorbar_<0 or 1>`, `peak_dense_pure_nodes_purity_75_peak_density_90`, `centrality_colorbar_<0 or 1>`.
  * The latter is stored at `<repo_root>/data_pipeline/plot_shuffled_modularity/` with the following filenames:
    * `shuffled_modularity_<cohort>_LR_<simplex>_all_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`; and `simplex` takes values `node`, `edge`, or `triangle`.
    * `delta_modularity_peak_dense_minus_none_<cohort>_LR_all_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`
    * `within_task_centrality_<cohort>_LR_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`
* Fig 4 consists of heatmaps and eigenbrains for high-amplitude functional connectivity.
  * The former is stored in `<repo_root>/data_pipeline/high_amplitude_functional_connectivity`, with filenames `plot_cross_measure_corr_with_FC_one_LR.png` and `plot_high_amp_FC_<MOTOR or WM>_one_LR_<tradition, peak_dense_pure_node, or peak>_functional_connectivity_rest_contrast_1_text_flag_0.pdf`
  * The latter is stored in `<repo_root>/data_pipeline/high_amplitude_FC_eigenbrains`, with filenames `data_high_amp_FC_<MOTOR or WM>_one_LR_peak_dense_pure_node_functional_connectivity_1_<1, 2, or 3>_title_flag_0.png`
* Fig 5 consists of a heatmap and a scatter plot of framewise pairwise distances, some brain maps,and a number of relevant cohort-wide statistics.
  * All non-brain-maps are at `<repo_root>/data_pipeline/pairwise_distances`, with the following filenames:
    * heatmap: `plot_scatter_pairwise_distances_one_subject_<node or edge>_<upper, lower, bounded>.png`
    * scatter plot: `plot_scatter_pairwise_distances_one_subject.png`
    * statistics: `plot_cohortwide_<one or two>_parabolas<(empty), or _zoomed>.png`, `plot_R_squared_<one or two>.png`, `plot_bound_violation_<one or two>.png`,
  * The brain maps are stored at `<repo_root>/data_pipeline/pairwise_distances_brain_plots/subject-100206_task-<task>_acq-<session>_schaefer100x7_ts.1D_timepoint_t1<idx>_tr_<TR>.png`, where `task` takes values `REST` or `WM`; session takes values `LR_run-1` or `LR` (respectively); `idx` takes values `1` or `2`, and `TR` takes values `363`, `377`, `8`, or `19`.
* Fig 6 consists of scatter plots and confidence intervals for brain-behavior correlation. They are stored at `<repo root>/data_pipeline/plot_brain_behavior_correlation`.
  * Filenames of scatter plots are `plot_brain_behavior_correlation_scatter_edge_modularity_vs_<behavioral feature>.pdf`, where `behavioral feature` takes values `NEOFAC_C`, `ASR_Intn_T`, `ASR_Extn_T`.
  * Filenames of confidence interval plots are `plot_brain_behavior_correlation_edge_cohort_<cohort>_session_both_parcellation_schaefer100x7_tail_2_response_<reponse type>_control_<control type>`, where `cohort` takes values `one`, or `all`; `reponse type` takes values `all`, or `select`; and `control type` takes values `none` and `all`.
* Fig S1 is a counterpart of Fig 2. The plots are stored at `<repo_root>/data_pipeline/plot_modularity_comparison/plot_modularity_comparison_cohort_<cohort>_<session>_<feature processing>_<parcellation>_with_sig.pdf`, where `cohort` takes values `one`, or `two`; `session` takes values `LR`, or `RL`; `feature_processing` takes values `raw_features`, `coherence`, or `pca_variance_threshold_90`, `pca_fixed_components_30`, `pca_fixed_components_35`, or `pca_fixed_components_40`; parcellation` takes values `schaefer100x7`, `schaefer200x7`.
* Fig S2 was generated directly by expt 01h and expt 01i in `expt`.
* Fig S3 is a counterpart of Fig 2a-c. Plots stored at `<scratch directory>/simplex_mapper_raw_features_cohort_one_LR_<simplex>_schaefer100x7/simplexMapper_<simplex>_<subject>_LR_schaefer100x7.pdf`, where `simplex` takes values `node`, `edge`, or `triangle`; `subject` takes values 100206, 125525, 144832, 192641, 725751.
* Fig S4 is a counterpart of Fig 2b, 3c-d.
  * Plots for the first column are stored at `<scratch directory>/simplex_mapper_raw_features_cohort_one_LR_<simplex>_schaefer100x7/simplexMapper_edge_<subject>_LR_schaefer100x7.pdf`, where `subject` takes values 100206, 125525, 144832, 192641, 725751.
  * Plots for the other columns are stored at `<repo_root>/data_pipeline/individual_mapper/simplex_mapper_edge_<subject>_LR_shaefer100x7_<filename suffix>.pdf`, where `subject` takes values 100206, 125525, 144832, 192641, 725751; `filename suffix` takes values `peak_density_colorbar_<0 or 1>`, `peak_dense_pure_nodes_purity_75_peak_density_90`.
* Fig S5 is a counterpart of Fig 3. The plots are stored at `<repo_root>/data_pipeline/plot_shuffled_modularity/` with the following filenames:
    * `shuffled_modularity_<cohort>_LR_<simplex>_matched_random_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`; and `simplex` takes values `node`, `edge`, or `triangle`.
    * `delta_modularity_peak_dense_minus_matched_random_<cohort>_LR_all_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`
    * `within_task_centrality_<cohort>_LR_peak_95_purity_75_peak_density_90.pdf`, where `cohort` takes values `one`, or `two`
* Fig S6 contains histograms of node purity. The plots are stored at `<repo_root>/data_pipeline/node_purity/plot_purity_distribution_edge_<cohort>_<session>_schaefer100x7_<autoYlim, fixedYlim, or logY>.png`, where `cohort` takes values `one`, or `two`; `session` takes values `LR`, or `RL`.
* Fig S7 is a counterpart of Fig 3. The plots are stored at `<repo_root>/data_pipeline/plot_shuffled_modularity/` with the following filenames:
    * `shuffled_modularity_<cohort>_LR_<simplex>_all_peak_95_purity_75_peak_density_<threshold>.pdf`, where `cohort` takes values `one`, or `two`; and `simplex` takes values `node`, `edge`, or `triangle`.
    * `delta_modularity_peak_dense_minus_all_<cohort>_LR_all_peak_95_purity_75_peak_density_<threshold>.pdf`, where `cohort` takes values `one`, or `two`
    * `within_task_centrality_<cohort>_LR_peak_95_purity_75_peak_density_<threshold>.pdf`, where `cohort` takes values `one`, or `two`
* Fig S8 contains more eigenbrains, which are stored in `<repo_root>/data_pipeline/high_amplitude_FC_eigenbrains`, with filenames `data_high_amp_FC_<MOTOR or WM>_two_LR_peak_dense_pure_node_functional_connectivity_1_<1, 2, or 3>_title_flag_0.png`
* Fig S9 is a counterpart of Fig 4. It consists of heatmaps and eigenbrains for high-amplitude functional connectivity.
    * The former is stored in `<repo_root>/data_pipeline/high_amplitude_functional_connectivity`, with filenames `plot_cross_measure_corr_with_FC_two_LR.png` and `plot_high_amp_FC_<MOTOR or WM>_two_LR_<tradition, peak_dense_pure_node, or peak>_functional_connectivity_rest_contrast_1_text_flag_0.pdf`
    * The latter is stored in `<repo_root>/data_pipeline/high_amplitude_FC_eigenbrains`, with filenames `data_high_amp_FC_<MOTOR or WM>_two_LR_peak_dense_pure_node_functional_connectivity_1_<1, 2, or 3>_title_flag_0.png`
* Fig S10 - S12 consists of confidence intervals for brain-behavior correlation. They are stored at `<repo root>/data_pipeline/plot_brain_behavior_correlation` with the following filenames
  * `plot_brain_behavior_correlation_<simplex>_cohort_<cohort>_session_both_parcellation_schaefer100x7_tail_2_response_<reponse type>_control_<control type>`, where `simplex` takes values `node`, `edge`, or `triangle`; `cohort` takes values `one`, or `all`; `reponse type` takes values `all`, or `select`; and `control type` takes values `none` and `all`.
* Fig S13 contains scatter plots of quality of modularity between the LR and RL sessions. They are plotted from data in `<repo_root>/data_pipeline/simplex_mappers/simplex_mapper_raw_features_cohort_all_session_both_schaefer100x7.csv`

## Tables

* Table S1 is `<repo_root>/data_pipeline/stat_modularity_comparison/stat_modularity_comparison_paired_ttest_polished.csv`.
* Table S2 is `<repo_root>/data_pipeline/stat_modularity_comparison/stat_modularity_comparison_covariate_adjustment_polished.csv`.
* Table S3 is `<repo_root>/data_pipeline/stat_shuffled_modularity/stat_shuffled_modularity_ttest_all_90_polished.csv`.
* Table S4 is `<repo_root>/data_pipeline/stat_centrality/stat_centrality_ttest_polished.csv`.
* Table S5 is `<repo_root>/data_pipeline/stat_centrality/stat_centrality_ancova_lme_polished.csv`.
* Table S6 is `<repo_root>/data_pipeline/stat_shuffled_modularity/stat_shuffled_modularity_ttest_matched_random_90.csv`.
* Table S7 is `<repo_root>/data_pipeline/stat_shuffled_modularity/stat_shuffled_modularity_ancova_all_90.csv`
* Table S8 is copied from screen output of `<repo_root>/expt/expt_expt_04d_make_purity_plot.py`.
* Table S9 is `<repo_root>/data_pipeline/stat_high_amplitude_functional_connectivity/correlation_with_FC_stats_one_LR.csv`.
* Table S10 is `<repo_root>/data_pipeline/brain_behavior_correlation/brain_behavior_corr_stats_cohort_one_all_features_no_control.csv`.
* Table S11 is `<repo_root>/data_pipeline/brain_behavior_correlation/brain_behavior_corr_stats_cohort_one_select_features_all_controls.csv`.
* Table S12 is `<repo_root>/data_pipeline/brain_behavior_correlation/brain_behavior_corr_stats_cohort_all_select_features_all_controls.csv`.