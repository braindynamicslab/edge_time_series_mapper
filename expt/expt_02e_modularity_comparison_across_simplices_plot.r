# ==============================================================================
# PACKAGE MANAGEMENT
# ==============================================================================
# Check for required packages and load them
# Stops execution with helpful message if any packages are missing
required_pkgs <- c("readr","dplyr","tidyr","stringr","ggplot2","ragg","grid")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop(
    "Missing packages: ", paste(missing_pkgs, collapse = ", "),
    "\nInstall with:\ninstall.packages(c(", paste0('"', missing_pkgs, '"', collapse = ", "), "))"
  )
}
invisible(lapply(required_pkgs, library, character.only = TRUE))

# Check if patchwork is available for combining plots (optional)
has_patchwork <- requireNamespace("patchwork", quietly = TRUE)

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================
# Define all input and output directories
base_dir <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/simplex_mappers"
plot_dir <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/plot_modularity_comparison"

# Cohort definition files
cohort1_LR_txt <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/data_cohort/cohort_one_session_LR.csv"
cohort1_RL_txt <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/data_cohort/cohort_one_session_RL.csv"
cohort2_LR_txt <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/data_cohort/cohort_two_session_LR.csv"

# Pre-computed statistical results
stats_file <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/stat_modularity_comparison/stat_modularity_comparison_paired_ttest.csv"

# Create output directory if it doesn't exist
out_dir <- file.path(plot_dir)
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ==============================================================================
# FIGURE SIZE AND TEXT PARAMETERS
# ==============================================================================
# Panel dimensions
PANEL_WIDTH_MM  <- 60
PANEL_HEIGHT_MM <- 50
PANEL_RES_DPI   <- 600

# Combined figure dimensions
COMBINED_WIDTH_MM  <- 180
COMBINED_HEIGHT_MM <- 180
COMBINED_RES_DPI   <- 600

# Text sizes
BASE_FONT_SIZE <- 10           # Controls all text
SIG_LABEL_SIZE <- 3            # Significance markers (*, **, ***)
FONT_FAMILY <- "Helvetica"     # Font family

# ==============================================================================
# FUNCTION: detect_subject_col
# ==============================================================================
# Purpose: Automatically detect the subject/participant ID column in a dataframe
# Input:   df - a dataframe with subject identifiers
# Output:  String containing the name of the subject column
# Notes:   Looks for common variants (case-insensitive): subject, subj, 
#          participant, subject_id. Stops with error if none found.
detect_subject_col <- function(df) {
  nm <- names(df)
  hit <- nm[stringr::str_which(tolower(nm), "^(subject|subj|participant|subject_id)$")][1]
  if (is.na(hit)) stop("Could not detect Subject column. Please rename to one of: subject, subj, participant, subject_id")
  hit
}

# ==============================================================================
# FUNCTION: make_long_modularity
# ==============================================================================
# Purpose: Load a CSV file and reshape it from wide to long format for plotting
# Input:   csv_path - path to CSV file containing modularity data
#          cohort_ids - optional vector of subject IDs to filter by
# Output:  Long-format dataframe with columns: Subject, feature_raw, modularity, feature
# Process: 1. Reads CSV file
#          2. Detects and renames subject column to "Subject"
#          3. Pivots ONLY modularity columns to long format (excludes num_nodes, num_edges)
#          4. Categorizes features into node/edge/triangle based on column names
#          5. Filters by cohort if specified
#          6. Returns factorized feature column for proper plotting order
make_long_modularity <- function(csv_path, cohort_ids = NULL) {
  df_all <- readr::read_csv(csv_path, show_col_types = FALSE)
  
  # Identify the subject column (flexible naming)
  subject_col <- detect_subject_col(df_all)
  
  # Reshape from wide to long format
  long_all <- df_all |>
    dplyr::rename(Subject = !!subject_col) |>
    dplyr::mutate(Subject = as.character(Subject)) |>
    # Pivot ONLY modularity columns (excludes num_nodes, num_edges metadata)
    tidyr::pivot_longer(
      cols = tidyselect::matches("modularity", ignore.case = TRUE),
      names_to = "feature_raw", values_to = "modularity"
    ) |>
    # Categorize each feature based on its column name
    dplyr::mutate(
      feature = dplyr::case_when(
        stringr::str_detect(tolower(feature_raw), "node") ~ "node",
        stringr::str_detect(tolower(feature_raw), "edge") ~ "edge",
        stringr::str_detect(tolower(feature_raw), "tri")  ~ "triangle",
        TRUE ~ NA_character_
      ),
      modularity = as.numeric(modularity)
    ) |>
    dplyr::filter(!is.na(feature), !is.na(modularity))
  
  # Filter to specific cohort if provided
  if (!is.null(cohort_ids)) {
    long_all <- long_all |>
      dplyr::filter(Subject %in% cohort_ids)
  }
  
  # Convert feature to factor with correct ordering for plots
  present_levels <- intersect(c("node","edge","triangle"), unique(long_all$feature))
  long_all |>
    dplyr::mutate(feature = factor(feature, levels = present_levels))
}

# ==============================================================================
# PLOTTING CONSTANTS
# ==============================================================================
# Line widths and styling parameters for consistent publication-quality plots
LW_VIOLIN  <- 0.35    # Line width for violin plot outlines
LW_BOX     <- 0.85    # Line width for box plot outlines
BOX_FATTEN <- 2       # Thickness multiplier for box plot median line
LW_AXIS    <- 0.55    # Line width for axis lines and ticks

# ==============================================================================
# FUNCTION: element_line_lw
# ==============================================================================
# Purpose: Create ggplot2 line elements with backward compatibility
# Input:   color - line color
#          linewidth - line width
#          ... - additional arguments passed to element_line
# Output:  ggplot2 element_line object
# Notes:   Handles API change in ggplot2 where 'size' was renamed to 'linewidth'
element_line_lw <- function(color = "black", linewidth = 0.5, ...) {
  if ("linewidth" %in% names(formals(ggplot2::element_line))) {
    ggplot2::element_line(color = color, linewidth = linewidth, ...)
  } else {
    ggplot2::element_line(color = color, size = linewidth, ...)
  }
}

# ==============================================================================
# FUNCTION: theme_nature
# ==============================================================================
# Purpose: Create a custom ggplot2 theme for publication-quality figures
# Input:   base_size - base font size in points
#          base_family - font family name
# Output:  ggplot2 theme object
# Notes:   Styled for Nature journal specifications with clean, minimal design
theme_nature <- function(base_size = BASE_FONT_SIZE, base_family = FONT_FAMILY) {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      # Text elements - all black
      text = ggplot2::element_text(color = "black", family = base_family),
      plot.background  = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      
      # Axis styling
      axis.line  = element_line_lw(color = "black", linewidth = LW_AXIS),
      axis.ticks = element_line_lw(color = "black", linewidth = LW_AXIS),
      axis.ticks.length = grid::unit(2.2, "mm"),
      
      # Axis text with appropriate margins
      axis.text.x  = ggplot2::element_text(color = "black", margin = ggplot2::margin(t = 6)),
      axis.text.y  = ggplot2::element_text(color = "black", margin = ggplot2::margin(r = 6)),
      axis.title.x = ggplot2::element_text(color = "black"),
      axis.title.y = ggplot2::element_text(color = "black", margin = ggplot2::margin(r = 10)),
      
      # Plot title centered and bold
      plot.title = ggplot2::element_text(color = "black", hjust = 0.5, face = "plain", margin = ggplot2::margin(b = 15)),
      plot.margin = ggplot2::margin(12, 10, 8, 8),
      
      # No legend by default
      legend.position = "none"
    )
}

# ==============================================================================
# COLOR PALETTE
# ==============================================================================
# Color scheme for different simplex types (node, edge, triangle)
# Uses ColorBrewer blues palette for visual consistency
pal_simplex <- c(
  node = "#C6DBEF",      # Light blue
  edge = "#6BAED6",      # Medium blue
  triangle = "#2171B5"   # Dark blue
)

# ==============================================================================
# FUNCTION: plot_violin_box
# ==============================================================================
# Purpose: Create a violin+box plot for modularity data across simplex types
# Input:   d - long-format dataframe with columns: feature (factor), modularity (numeric)
#          title - plot title string
#          y_max - maximum y-axis value for consistent scaling across panels
#          show_y - logical, whether to show y-axis label
# Output:  ggplot2 plot object
# Process: 1. Creates violin plot showing distribution
#          2. Overlays box plot showing median and quartiles
#          3. Uses custom color palette for different simplex types
#          4. Applies Nature journal theme
# Notes:   Handles ggplot2 API differences (size vs linewidth parameter)
plot_violin_box <- function(d, title, y_max, show_y = TRUE) {
  
  # Extract color palette for the feature levels present in data
  pal <- pal_simplex[levels(d$feature)]
  
  ggplot(d, aes(x = feature, y = modularity, fill = feature)) +
    # Violin plot layer - shows full distribution
    geom_violin(
      trim = FALSE, scale = "width", width = 0.85,
      alpha = 0.95, color = "black",
      linewidth = if ("linewidth" %in% names(formals(ggplot2::geom_violin))) LW_VIOLIN else NULL,
      size      = if (!("linewidth" %in% names(formals(ggplot2::geom_violin)))) LW_VIOLIN else NULL
    ) +
    # Box plot layer - shows median, quartiles, and outliers
    geom_boxplot(
      width = 0.16, outlier.shape = NA,
      fill = "white", color = "black", fatten = BOX_FATTEN,
      linewidth = if ("linewidth" %in% names(formals(ggplot2::geom_boxplot))) LW_BOX else NULL,
      size      = if (!("linewidth" %in% names(formals(ggplot2::geom_boxplot)))) LW_BOX else NULL
    ) +
    # Apply color palette
    scale_fill_manual(values = pal, guide = "none") +
    # Labels
    labs(
      title = title,
      x = NULL,
      y = if (isTRUE(show_y)) "Quality of Modularity" else NULL
    ) +
    # Y-axis scaling with consistent limits across all panels
    scale_y_continuous(
      limits = c(0, y_max),
      expand = expansion(mult = c(0.06, 0.08))
    ) +
    coord_cartesian(clip = "off") +
    theme_nature()
}

# ==============================================================================
# FUNCTION: save_png
# ==============================================================================
# Purpose: Save a ggplot object to high-resolution PNG file
# Input:   p - ggplot object to save
#          filename - output file path
#          width_mm - width in millimeters
#          height_mm - height in millimeters
#          res - resolution in DPI
# Output:  PNG file written to disk
# Notes:   Uses ragg::agg_png for high-quality anti-aliased output
save_png <- function(p, filename, width_mm = PANEL_WIDTH_MM, height_mm = PANEL_HEIGHT_MM, res = PANEL_RES_DPI) {
  ragg::agg_png(
    filename = filename,
    width = width_mm, height = height_mm, units = "mm",
    res = res, background = "white"
  )
  print(p)
  dev.off()
}

# ==============================================================================
# FUNCTION: save_pdf
# ==============================================================================
# Purpose: Save a ggplot object to vector PDF file
# Input:   p - ggplot object to save
#          filename - output file path
#          width_mm - width in millimeters
#          height_mm - height in millimeters
# Output:  PDF file written to disk
# Notes:   Vector format, infinitely scalable, better for publications
save_pdf <- function(p, filename, width_mm = PANEL_WIDTH_MM, height_mm = PANEL_HEIGHT_MM) {
  ggplot2::ggsave(
    filename = filename,
    plot = p,
    width = width_mm,
    height = height_mm,
    units = "mm",
    device = "pdf",
    useDingbats = FALSE  # Better compatibility with editors
  )
}

# ==============================================================================
# FUNCTION: make_descriptive_filename
# ==============================================================================
# Purpose: Generate descriptive, structured filenames for output files
# Input:   panel_id - panel identifier (e.g., "a", "b", "c")
#          csv_file - name of input CSV file
#          cohort_type - "RL", "LR", or "cohort2" session type
#          title - plot title (not used in new naming scheme)
# Output:  Descriptive filename string (without extension)
# Format:  plot_modularity_comparison_cohort_<one/two>_<LR/RL>_<condition>_schaefer<100x7/200x7>
make_descriptive_filename <- function(panel_id, csv_file, cohort_type, title) {
  
  # Parse cohort number from cohort_type
  cohort_num <- if (cohort_type == "cohort2") {
    "two"
  } else {
    "one"
  }
  
  # Parse session from CSV filename
  session <- stringr::str_extract(csv_file, "(LR|RL)")
  
  # Parse condition from CSV filename
  # Extract: raw_features, coherence, pca_variance_threshold_90, pca_fixed_components_XX
  condition <- stringr::str_extract(csv_file, 
                                    "(raw_features|coherence|pca_variance_threshold_\\d+|pca_fixed_components_\\d+)")
  
  # Parse parcellation from CSV filename
  parcellation <- stringr::str_extract(csv_file, "schaefer\\d+x\\d+")
  
  # Construct filename (without extension)
  filename <- paste0(
    "plot_modularity_comparison",
    "_cohort_", cohort_num,
    "_", session,
    "_", condition,
    "_", parcellation
  )
  
  return(filename)
}

# ==============================================================================
# LOAD COHORT DEFINITIONS
# ==============================================================================
# Read subject ID lists for each cohort/session combination
# Files are CSV format with subject IDs

cohort1_LR_ids <- readr::read_csv(cohort1_LR_txt, show_col_types = FALSE) |>
  dplyr::pull(1) |>
  as.character()

cohort1_RL_ids <- readr::read_csv(cohort1_RL_txt, show_col_types = FALSE) |>
  dplyr::pull(1) |>
  as.character()

cohort2_ids <- readr::read_csv(cohort2_LR_txt, show_col_types = FALSE) |>
  dplyr::pull(1) |>
  as.character()

# ==============================================================================
# LOAD PRE-COMPUTED STATISTICAL RESULTS
# ==============================================================================
# Read pre-computed t-test results with significance markers
precomputed_stats <- readr::read_csv(stats_file, show_col_types = FALSE)

# ==============================================================================
# FUNCTION: get_significance_for_panel
# ==============================================================================
# Purpose: Extract significance results for a specific panel from pre-computed table
# Input:   panel_spec - one row from specs dataframe
#          stats_table - pre-computed statistics dataframe with columns:
#                        condition, cohort, session, parcellation, 
#                        simplex_1, simplex_2, significance
# Output:  Dataframe with columns: comparison, feature1, feature2, sig_marker
#          Returns NULL if no matching results found
# Notes:   Maps panel metadata (condition, cohort, session, parcellation) to stats table
get_significance_for_panel <- function(panel_spec, stats_table) {
  
  # Parse metadata from CSV filename
  csv_name <- panel_spec$csv
  
  # Extract condition from filename
  condition <- stringr::str_extract(csv_name, 
                                    "(raw_features|coherence|pca_variance_threshold_\\d+|pca_fixed_components_\\d+)")
  
  # Determine cohort
  cohort <- if (panel_spec$cohort_type == "cohort2") {
    "two"
  } else {
    "one"
  }
  
  # Extract session
  session <- stringr::str_extract(csv_name, "(LR|RL)")
  
  # Extract parcellation
  parcellation <- stringr::str_extract(csv_name, "schaefer\\d+x\\d+")
  
  # Filter stats table to matching rows
  panel_stats <- stats_table |>
    dplyr::filter(
      condition == !!condition,
      cohort == !!cohort,
      session == !!session,
      parcellation == !!parcellation
    )
  
  # Return NULL if no matches found
  if (nrow(panel_stats) == 0) {
    return(NULL)
  }
  
  # Convert to simplified format for plotting
  panel_stats |>
    dplyr::mutate(
      comparison = paste(simplex_1, "vs", simplex_2),
      feature1 = simplex_1,
      feature2 = simplex_2,
      sig_marker = significance_bonferroni
    ) |>
    dplyr::select(comparison, feature1, feature2, sig_marker)
}

# ==============================================================================
# FUNCTION: add_significance_bars_to_plot
# ==============================================================================
# Purpose: Add significance bars and markers to plots using pre-computed results
# Input:   base_plot - ggplot object
#          sig_results - dataframe from get_significance_for_panel() with columns:
#                        comparison, feature1, feature2, sig_marker
#          y_max - y-axis maximum for positioning bars
# Output:  Modified ggplot with significance annotations (bars and labels)
# Process: 1. Filters to significant results (sig_marker != "0")
#          2. Maps feature names to x-axis positions
#          3. Calculates y-positions for bars (stacked to avoid overlap)
#          4. Adds horizontal line segments
#          5. Adds significance labels (*, **, ***)
# Notes:   Returns original plot unchanged if no significant results
add_significance_bars_to_plot <- function(base_plot, sig_results, y_max) {
  
  # Filter to significant results only (exclude "0")
  sig_only <- sig_results |>
    dplyr::filter(sig_marker != "0")
  
  # Return unchanged if no significant results
  if (nrow(sig_only) == 0) {
    message("  No significant comparisons")
    return(base_plot)
  }
  
  message("  Found ", nrow(sig_only), " significant comparison(s)")
  
  # Map feature names to x-axis positions
  feature_map <- c("node" = 1, "edge" = 2, "triangle" = 3)
  
  # Calculate bar positions
  # Different heights prevent overlapping bars
  # Farther comparisons placed higher
  sig_segments <- sig_only |>
    dplyr::mutate(
      x_start = feature_map[tolower(feature1)],
      x_end = feature_map[tolower(feature2)],
      # Position bars at different heights based on span
      # Handle both comparison orders (e.g., "edge,node" and "node,edge")
      span = abs(x_end - x_start),
      y_position = dplyr::case_when(
        # Span of 2 (node-triangle or triangle-node): highest
        span == 2 ~ y_max,
        # Span of 1, involving position 3 (edge-triangle or triangle-edge): middle
        (span == 1 & (x_start == 3 | x_end == 3)) ~ y_max - 0.12 * y_max,
        # Span of 1, between positions 1-2 (node-edge or edge-node): lowest
        (span == 1 & (x_start <= 2 & x_end <= 2)) ~ y_max - 0.19 * y_max,
        TRUE ~ y_max
      ),
      # Adjust endpoints for adjacent comparisons to avoid touching violins
      x_start_adj = dplyr::if_else(x_end - x_start == 1, x_start + 0.1, x_start),
      x_end_adj = dplyr::if_else(x_end - x_start == 1, x_end - 0.1, x_end),
      x_mid = (x_start_adj + x_end_adj) / 2  # Midpoint for label placement
    )
  
  # Add horizontal line segments (handles ggplot2 API differences)
  if ("linewidth" %in% names(formals(ggplot2::geom_segment))) {
    base_plot <- base_plot + 
      ggplot2::geom_segment(
        data = sig_segments,
        ggplot2::aes(x = x_start_adj, xend = x_end_adj, 
                     y = y_position, yend = y_position),
        inherit.aes = FALSE,
        color = "black",
        linewidth = 0.6
      )
  } else {
    base_plot <- base_plot + 
      ggplot2::geom_segment(
        data = sig_segments,
        ggplot2::aes(x = x_start_adj, xend = x_end_adj, 
                     y = y_position, yend = y_position),
        inherit.aes = FALSE,
        color = "black",
        size = 0.6
      )
  }
  
  # Add significance markers (*, **, ***) above bars
  base_plot <- base_plot +
    ggplot2::geom_text(
      data = sig_segments,
      ggplot2::aes(x = x_mid, y = y_position, label = sig_marker),
      inherit.aes = FALSE,
      vjust = -0.02,  # Position slightly above the bar
      size = SIG_LABEL_SIZE,
      color = "black"
    )
  
  return(base_plot)
}

# ==============================================================================
# PANEL SPECIFICATIONS
# ==============================================================================
# Define all analysis panels with their corresponding data files and metadata
# Each row represents one panel in the final supplementary figure
# Columns:
#   - panel: panel identifier (a, b, c, etc.)
#   - csv: filename of input CSV in base_dir
#   - cohort_type: "LR", "RL", or "cohort2" (determines which subjects to include)
#   - title: descriptive title for the plot

specs <- data.frame(
  panel = c("a", "b", "c", "d", "e", "f", "g", "h", "i"), #, "j"),
  csv = c(
    "simplex_mapper_raw_features_cohort_one_RL_schaefer100x7.csv",
    "simplex_mapper_raw_features_cohort_one_LR_schaefer100x7.csv",
    "simplex_mapper_raw_features_cohort_one_LR_schaefer200x7.csv",
    "simplex_mapper_raw_features_cohort_two_LR_schaefer100x7.csv",
    "simplex_mapper_coherence_cohort_one_LR_schaefer100x7.csv",
    "simplex_mapper_pca_variance_threshold_90_cohort_one_LR_schaefer100x7.csv",
    "simplex_mapper_pca_fixed_components_30_cohort_one_LR_schaefer100x7.csv",
    "simplex_mapper_pca_fixed_components_35_cohort_one_LR_schaefer100x7.csv",
    "simplex_mapper_pca_fixed_components_40_cohort_one_LR_schaefer100x7.csv"
    #"simplex_mapper_pca_fixed_components_50_cohort_one_LR_schaefer100x7.csv"
  ),
  cohort_type = c("RL", "LR", "LR", "cohort2", "LR", "LR", "LR", "LR", "LR"), #, "LR"),
  title = c(
    "Exploration cohort, Schaefer 100×7, RL",
    "Exploration cohort, Schaefer 100×7, LR",
    "Exploration cohort, Schaefer 200×7, LR",
    "Replication cohort, Schaefer 100×7, LR",
    "Exploration cohort, Schaefer 100×7, LR (coherence)",
    "Exploration cohort, Schaefer 100×7, LR (PCA 90% variance)",
    "Exploration cohort, Schaefer 100×7, LR (PCA 30 components)",
    "Exploration cohort, Schaefer 100×7, LR (PCA 35 components)",
    "Exploration cohort, Schaefer 100×7, LR (PCA 40 components)"
    #"Exploration cohort, Schaefer 100×7, LR (PCA 50 components)"
  ),
  stringsAsFactors = FALSE
)

# ==============================================================================
# DATA LOADING
# ==============================================================================
# Load and process all data files specified in specs
# Creates a named list where each element is a long-format dataframe
# for one panel, filtered to the appropriate cohort

# Initialize empty list with panel names
data_list <- setNames(vector("list", nrow(specs)), specs$panel)

# Loop through each panel specification
for (i in seq_len(nrow(specs))) {
  
  # Construct full path to CSV file
  csv_path <- file.path(base_dir, specs$csv[i])
  if (!file.exists(csv_path)) stop("Missing CSV: ", csv_path)
  
  # Select appropriate cohort IDs based on session type
  cohort_ids_to_use <- switch(specs$cohort_type[i],
                              "RL" = cohort1_RL_ids,
                              "LR" = cohort1_LR_ids,
                              "cohort2" = cohort2_ids,
                              stop("Unknown cohort type: ", specs$cohort_type[i])
  )
  
  # Load and transform data to long format, filtered by cohort
  data_list[[specs$panel[i]]] <- make_long_modularity(
    csv_path = csv_path,
    cohort_ids = cohort_ids_to_use
  )
}

# ==============================================================================
# DETERMINE COMMON Y-AXIS MAXIMUM
# ==============================================================================
# Calculate a common y-axis maximum across all panels for visual consistency
# This allows direct comparison of distributions across different analyses

# Combine all modularity values from all panels
all_vals <- unlist(lapply(data_list, function(d) d$modularity), use.names = FALSE)

# Find the maximum value
y_max_raw <- max(all_vals, na.rm = TRUE)

# Ensure minimum y-max of 0.8
y_max <- max(0.8, y_max_raw)

# Round up to nearest 0.05 for cleaner axis labels
y_max <- ceiling(y_max * 20) / 20

message("Using common y-max = ", y_max)

# ==============================================================================
# GENERATE PLOTS WITH PRE-COMPUTED SIGNIFICANCE
# ==============================================================================
# Create violin+box plots for each panel
# Generate both versions: without and with significance bars
# Save in both PNG and PDF formats

# Initialize empty lists for plots
plots <- setNames(vector("list", nrow(specs)), specs$panel)
plots_with_sig <- setNames(vector("list", nrow(specs)), specs$panel)

# Loop through each panel specification
for (i in seq_len(nrow(specs))) {
  
  panel_id <- specs$panel[i]
  d <- data_list[[panel_id]]
  
  message("\nProcessing Panel ", panel_id, ":")
  
  # Create base plot using common y-axis maximum
  p_base <- plot_violin_box(
    d = d,
    title = specs$title[i],
    y_max = y_max,
    show_y = TRUE
  )
  
  # Store base plot
  plots[[panel_id]] <- p_base
  
  # Get pre-computed significance for this panel
  sig_results <- get_significance_for_panel(specs[i, ], precomputed_stats)
  
  # Add significance bars if results available
  if (!is.null(sig_results)) {
    p_with_sig <- add_significance_bars_to_plot(
      base_plot = p_base,
      sig_results = sig_results,
      y_max = y_max
    )
  } else {
    message("  No significance results available")
    p_with_sig <- p_base
  }
  
  # Store plot with significance
  plots_with_sig[[panel_id]] <- p_with_sig
  
  # Generate base filename (without extension)
  base_filename <- make_descriptive_filename(
    panel_id = panel_id,
    csv_file = specs$csv[i],
    cohort_type = specs$cohort_type[i],
    title = specs$title[i]
  )
  
  # Save base plot (without significance) in both formats
  save_png(p_base, file.path(out_dir, paste0(base_filename, ".png")))
  save_pdf(p_base, file.path(out_dir, paste0(base_filename, ".pdf")))
  # Save plot with significance in both formats
  save_png(p_with_sig, file.path(out_dir, paste0(base_filename, "_with_sig.png")))
  save_pdf(p_with_sig, file.path(out_dir, paste0(base_filename, "_with_sig.pdf")))
  
  message("  Saved: ", base_filename, ".png/.pdf")
  message("  Saved: ", base_filename, "_with_sig.png/.pdf")
}

# ==============================================================================
# CREATE COMBINED FIGURES (OPTIONAL)
# ==============================================================================
# If patchwork package is available, combine individual panels into
# multi-panel figures (3 rows layout)

if (has_patchwork) {
  
  library(patchwork)
  
  message("\n", paste(rep("=", 60), collapse = ""))
  message("CREATING COMBINED FIGURES")
  message(paste(rep("=", 60), collapse = ""))
  
  # ===========================================================================
  # Combined figure WITHOUT significance bars
  # ===========================================================================
  
  # Combine plots in 3-row layout:
  # Row 1: panels a, b, c
  # Row 2: panels d, e, f
  # Row 3: panels g, h, i
  comb <- (plots[["a"]] | plots[["b"]] | plots[["c"]]) /
    (plots[["d"]] | plots[["e"]] | plots[["f"]]) /
    (plots[["g"]] | plots[["h"]] | plots[["i"]]) +
    patchwork::plot_annotation(tag_levels = "a")  # Add a, b, c, ... labels
  
  # Generate filename
  comb_name <- "plot_modularity_comparison_combined_all_panels"
  comb_file_png <- file.path(out_dir, paste0(comb_name, ".png"))
  comb_file_pdf <- file.path(out_dir, paste0(comb_name, ".pdf"))
  
  # Save combined figure as PNG
  ragg::agg_png(
    filename = comb_file_png,
    width = COMBINED_WIDTH_MM, height = COMBINED_HEIGHT_MM, units = "mm",
    res = COMBINED_RES_DPI, background = "white"
  )
  print(comb)
  dev.off()
  
  # Save combined figure as PDF
  ggplot2::ggsave(
    filename = comb_file_pdf,
    plot = comb,
    width = COMBINED_WIDTH_MM,
    height = COMBINED_HEIGHT_MM,
    units = "mm",
    device = "pdf",
    useDingbats = FALSE
  )
  
  message("Saved combined figure (no sig): ", basename(comb_file_png))
  message("Saved combined figure (no sig): ", basename(comb_file_pdf))
  
  # ===========================================================================
  # Combined figure WITH significance bars
  # ===========================================================================
  
  # Combine plots with significance bars in 3-row layout
  comb_sig <- (plots_with_sig[["a"]] | plots_with_sig[["b"]] | plots_with_sig[["c"]]) /
    (plots_with_sig[["d"]] | plots_with_sig[["e"]] | plots_with_sig[["f"]]) /
    (plots_with_sig[["g"]] | plots_with_sig[["h"]] | plots_with_sig[["i"]]) +
    patchwork::plot_annotation(tag_levels = "a")
  
  # Generate filename
  comb_name_sig <- "plot_modularity_comparison_combined_all_panels_with_sig"
  comb_file_sig_png <- file.path(out_dir, paste0(comb_name_sig, ".png"))
  comb_file_sig_pdf <- file.path(out_dir, paste0(comb_name_sig, ".pdf"))
  
  # Save combined figure with significance as PNG
  ragg::agg_png(
    filename = comb_file_sig_png,
    width = COMBINED_WIDTH_MM, height = COMBINED_HEIGHT_MM, units = "mm",
    res = COMBINED_RES_DPI, background = "white"
  )
  print(comb_sig)
  dev.off()
  
  # Save combined figure with significance as PDF
  ggplot2::ggsave(
    filename = comb_file_sig_pdf,
    plot = comb_sig,
    width = COMBINED_WIDTH_MM,
    height = COMBINED_HEIGHT_MM,
    units = "mm",
    device = "pdf",
    useDingbats = FALSE
  )
  
  message("Saved combined figure (with sig): ", basename(comb_file_sig_png))
  message("Saved combined figure (with sig): ", basename(comb_file_sig_pdf))
  
} else {
  
  message("\npatchwork not installed; skipping combined figures")
  
}

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================
# Print comprehensive summary of all outputs generated

message("\n", paste(rep("=", 60), collapse = ""))
message("ALL PROCESSING COMPLETE")
message(paste(rep("=", 60), collapse = ""))
message("Outputs saved to: ", out_dir)
message("\nFiles generated:")
message("  - ", nrow(specs), " panel PNGs (without significance)")
message("  - ", nrow(specs), " panel PDFs (without significance)")
message("  - ", nrow(specs), " panel PNGs (with significance)")
message("  - ", nrow(specs), " panel PDFs (with significance)")
if (has_patchwork) {
  message("  - 2 combined figure PNGs (with and without significance)")
  message("  - 2 combined figure PDFs (with and without significance)")
  message("\nTotal: ", nrow(specs) * 4 + 4, " files")
} else {
  message("\nTotal: ", nrow(specs) * 4, " files")
}
message(paste(rep("=", 60), collapse = ""))
