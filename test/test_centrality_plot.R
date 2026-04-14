# ==============================================================================
# STANDALONE CENTRALITY DATA DEBUG SCRIPT
# ==============================================================================
# Purpose: Load centrality data and classify nodes to debug peak-dense issue
# ==============================================================================

library(dplyr)
library(readr)

# ==============================================================================
# PARAMETERS (match main script)
# ==============================================================================
PEAK_THRESHOLD <- 95
PURITY_THRESHOLD <- 75
purity_threshold <- PURITY_THRESHOLD
PEAK_DENSITY_THRESHOLD <- 90
SESSION <- "LR"

# ==============================================================================
# CHOOSE COHORT TO DEBUG
# ==============================================================================
cohort <- "one"  # Change to "two" to debug the other cohort

# ==============================================================================
# LOAD DATA
# ==============================================================================
base_path <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/mapper_node_features"
filename <- sprintf("mapper_node_features_edge_%s_%s.csv", cohort, SESSION)
file_path <- file.path(base_path, filename)

message("Loading file: ", file_path)
message("File exists: ", file.exists(file_path))

# Auto-detect delimiter
first_line <- readLines(file_path, n = 1, warn = FALSE)
if (grepl("\t", first_line)) {
  df <- read_tsv(file_path, show_col_types = FALSE, progress = FALSE, comment = "#")
} else if (grepl(",", first_line)) {
  df <- read_csv(file_path, show_col_types = FALSE, progress = FALSE, comment = "#")
} else {
  df <- read_table(file_path, show_col_types = FALSE, progress = FALSE, comment = "#")
}

message("Data loaded: ", nrow(df), " rows, ", ncol(df), " columns")

# ==============================================================================
# SHOW COLUMN NAMES
# ==============================================================================
message("\n=== ALL COLUMN NAMES ===")
print(names(df))

message("\n=== AMPLITUDE COLUMNS ===")
amp_cols <- grep("amplitude_peak_density", names(df), value = TRUE, ignore.case = TRUE)
print(amp_cols)

message("\n=== CENTRALITY COLUMNS ===")
cent_cols <- grep("central", names(df), value = TRUE, ignore.case = TRUE)
print(cent_cols)

message("\n=== PURITY COLUMNS ===")
purity_cols <- grep("purity", names(df), value = TRUE, ignore.case = TRUE)
print(purity_cols)

# ==============================================================================
# CONSTRUCT COLUMN NAMES
# ==============================================================================
amp_col <- paste0("amplitude_peak_density_peak_threshold_", PEAK_THRESHOLD)
cent_col <- "mapper_stat_within_task_centrallity"
purity_col <- "mapper_stat_node_purity"

message("\n=== LOOKING FOR THESE COLUMNS ===")
message("Amplitude: ", amp_col)
message("  Exists? ", amp_col %in% names(df))
message("Centrality: ", cent_col)
message("  Exists? ", cent_col %in% names(df))
message("Purity: ", purity_col)
message("  Exists? ", purity_col %in% names(df))

# ==============================================================================
# STEP 1: CLASSIFY PURE NODES
# ==============================================================================
message("\n=== STEP 1: CLASSIFY PURE NODES ===")

df_node_properties <- df %>%
  mutate(
    is_pure_node = (.data[[purity_col]] >= purity_threshold / 100)
  )

message("Total nodes: ", nrow(df_node_properties))
message("Pure nodes (purity >= ", purity_threshold, "%): ", 
        sum(df_node_properties$is_pure_node, na.rm = TRUE))
message("Not pure: ", sum(!df_node_properties$is_pure_node, na.rm = TRUE))
message("NA purity: ", sum(is.na(df_node_properties$is_pure_node)))

# Filter to pure nodes only
df_node_properties <- df_node_properties %>%
  filter(is_pure_node == TRUE)

message("After filtering to pure nodes: ", nrow(df_node_properties), " rows")

# ==============================================================================
# STEP 2: CALCULATE PEAK-DENSE THRESHOLD
# ==============================================================================
message("\n=== STEP 2: CALCULATE THRESHOLD ===")

amplitude_values <- df_node_properties[[amp_col]]
amplitude_values <- amplitude_values[!is.na(amplitude_values)]

message("Valid amplitude values: ", length(amplitude_values))

if (length(amplitude_values) == 0) {
  stop("No valid amplitude values found!")
}

# Calculate threshold
amplitude_threshold <- quantile(
  amplitude_values, 
  probs = PEAK_DENSITY_THRESHOLD / 100,
  na.rm = TRUE
)

amplitude_95 <- quantile(
  amplitude_values, 
  probs = 0.95,
  na.rm = TRUE
)

message("Peak density threshold: ", PEAK_DENSITY_THRESHOLD, "th percentile")
message("Amplitude threshold value: ", amplitude_threshold)

message("Peak density threshold: 95th percentile")
message("Amplitude threshold value: ", amplitude_95)

# Summary statistics
message("\n=== AMPLITUDE DISTRIBUTION ===")
message("Min: ", min(amplitude_values))
message("Max: ", max(amplitude_values))
message("Mean: ", mean(amplitude_values))
message("Median: ", median(amplitude_values))
message("Unique values: ", length(unique(amplitude_values)))

message("\n=== QUANTILES ===")
print(quantile(amplitude_values, probs = seq(0, 1, 0.1)))

message("\n=== THRESHOLD COMPARISON ===")
message("Values >= threshold: ", sum(amplitude_values >= amplitude_threshold))
message("Values > threshold: ", sum(amplitude_values > amplitude_threshold))
message("Values < threshold: ", sum(amplitude_values < amplitude_threshold))
message("Values == threshold: ", sum(amplitude_values == amplitude_threshold))

# ==============================================================================
# STEP 3: CLASSIFY PEAK-DENSE
# ==============================================================================
message("\n=== STEP 3: CLASSIFY PEAK-DENSE ===")

df_node_properties <- df_node_properties %>%
  mutate(
    is_peak_dense = (.data[[amp_col]] >= amplitude_threshold)
  )

message("Peak-dense (TRUE): ", sum(df_node_properties$is_peak_dense == TRUE, na.rm = TRUE))
message("Not peak-dense (FALSE): ", sum(df_node_properties$is_peak_dense == FALSE, na.rm = TRUE))
message("NA: ", sum(is.na(df_node_properties$is_peak_dense)))

# ==============================================================================
# SHOW SAMPLE DATA
# ==============================================================================
message("\n=== SAMPLE OF CLASSIFIED DATA ===")
print(df_node_properties %>%
        select(all_of(c(amp_col, cent_col, purity_col)), is_pure_node, is_peak_dense) %>%
        head(20))

# ==============================================================================
# PLOT HISTOGRAM
# ==============================================================================
message("\n=== PLOTTING HISTOGRAM ===")
hist(amplitude_values, 
     breaks = 30,
     main = paste("Amplitude Distribution - Cohort", cohort),
     xlab = "Amplitude (peak density)",
     col = "lightblue",
     border = "white")
abline(v = amplitude_threshold, col = "red", lwd = 2, lty = 2)
legend("topright", 
       legend = paste0(PEAK_DENSITY_THRESHOLD, "th percentile = ", 
                       round(amplitude_threshold, 4)),
       col = "red", lty = 2, lwd = 2)

# ==============================================================================
# EXPORT FOR INSPECTION
# ==============================================================================
message("\n=== FINAL DATAFRAME ===")
message("Available in variable: df_node_properties")
message("Run: View(df_node_properties)")
message("Or: summary(df_node_properties)")

# Print structure
str(df_node_properties)