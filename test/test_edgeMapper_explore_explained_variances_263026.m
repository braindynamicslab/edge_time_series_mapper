cohort = "one";
session = "LR";
parcellation = "schaefer100x7";

config = fcn_utils_get_config();
output_data_directory = fullfile(config.scratch_dir, "cumulative_explained_variance_processed_simplex_time_series");
if ~isfolder(output_data_directory)
    mkdir(output_data_directory);
end

subjects = readtable(fullfile(config.repo_root, sprintf("data_pipeline/data_cohort/cohort_%s_session_LR.csv", cohort))).Subject;
target_explained_variance = 0.8;

simplices = [...
    "node", ...
    %"edge", ...
    %"triangle"... % too slow
    ];
for simplex = simplices
    if strcmp(simplex, "node")
        dim = 0;
    elseif strcmp(simplex, "edge")
        dim = 1;
    elseif strcmp(simplex, "triangle")
        dim = 2;
    end
    pca_explained_variance_per_component = nan(numel(subjects), nchoosek(100, dim+1));
    fprintf("========== %s ========== \n", simplex)
    parfor subject_idx = 1:numel(subjects)
        subject = subjects(subject_idx);
%        fprintf("%s - Processing the %d-th subject %d (total number of subjects: %d) \n",  datetime('now'), subject_idx, subject, numel(subjects));
         if mod(subject_idx, 40) == 0
             fprintf("%s - Processing the %d-th subject %d (reporting only every %d-th subject in the cohort (not processing order), total number of subjects: %d) \n",  datetime('now'), subject, 40, numel(subjects));
         end
        [reduced_data, feature_indices, tasks_instantwise, feature_removal_mask, missing_data_flag, pca_results, debug_data] = ...
            fcn_edgeMapper_get_processed_simplex_time_series_data(subject, parcellation, session, simplex, "dim_reduction_type", "pca_variance_threshold", "target_explained_variance", target_explained_variance, "verbose_flag", 0);
        pca_explained_variance_per_component(subject_idx, :) = debug_data.pca_explained_variance;
    end

    output_filename = sprintf("cumulative_explained_variance_processed_simplex_time_series_%s_cohort_%s_session_%s_%s.csv", simplex, cohort, session, parcellation);
    writematrix(...
        [subjects, cumsum(pca_explained_variance_per_component')'], ...
        fullfile(output_data_directory, output_filename));

%     figure;
%     plot(cumsum(pca_explained_variance_per_component'));
%     title(simplex);

end