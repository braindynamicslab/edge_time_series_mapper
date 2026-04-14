# ==============================================================================
# SHUFFLED MODULARITY AND CENTRALITY PLOTTING SCRIPT
# ==============================================================================
# Purpose: Generate violin+box plots comparing modularity across simplices
#          and centrality across pure node groups
# Author: [Your name]
# Date: [Current date]
# ==============================================================================

# ==============================================================================
# PACKAGE MANAGEMENT
# ==============================================================================
# Check for required packages and load them
# Stops execution with helpful message if any packages are missing
required_pkgs <- c("readr","dplyr","tidyr","stringr","ggplot2","ragg","grid","tibble")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop(
    "Missing packages: ", paste(missing_pkgs, collapse = ", "),
    "\nInstall with:\ninstall.packages(c(", paste0('"', missing_pkgs, '"', collapse = ", "), "))"
  )
}
invisible(lapply(required_pkgs, library, character.only = TRUE))

# ==============================================================================
# TUNABLE PARAMETERS
# ==============================================================================
PEAK_DENSITY_THRESHOLD <- 95  # Percentile cutoff among pure nodes: 80, 90, or 95

# Fixed parameters (match file generation settings)
PEAK_THRESHOLD <- 95      # Peak threshold used in file generation (in filename)
PURITY_THRESHOLD <- 75  # Minimum purity to classify as "pure node"
SESSION <- "LR"           # Only using LR session

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================
# Output directory
out_dir <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/plot_shuffled_modularity"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# FIGURE SIZE AND TEXT PARAMETERS
# ==============================================================================
# All plots use same dimensions
PLOT_WIDTH_MM  <- 50
PLOT_HEIGHT_MM <- 40
PLOT_RES_DPI   <- 600

# Text sizes
BASE_FONT_SIZE <- 8           # Controls all text
SIG_LABEL_SIZE <- 3            # Significance markers (*, **, ***)
FONT_FAMILY <- "Helvetica"

# Y-axis limits
YLIM_SHUFFLED_MOD <- c(-0.05, 0.8)
YLIM_DELTA_MOD    <- c(-0.20, 0.05)
YLIM_CENTRALITY   <- c(-5, 15)

# Line widths and styling parameters
LW_VIOLIN  <- 0.35
LW_BOX     <- 0.85
BOX_FATTEN <- 2
LW_AXIS    <- 0.55
LW_HLINE   <- 0.45

VIOLIN_WIDTH <- 0.85
BOX_WIDTH    <- 0.16

ASTERISK_VJUST <- -0.4

# ==============================================================================
# COLOR PALETTES
# ==============================================================================
blue_light  <- "#C6DBEF"
blue_mid    <- "#6BAED6"
blue_dark   <- "#2171B5"

pal_simplex <- c(
  "Node"     = blue_light,
  "Edge"     = blue_mid,
  "Triangle" = blue_dark
)

pal_centrality <- c(
  "Peak-dense\npure nodes" = blue_mid,
  "All other\npure nodes"  = blue_mid
)

# ==============================================================================
# FUNCTION: element_line_lw
# ==============================================================================
# Purpose: Create ggplot2 line elements with backward compatibility
# Handles API change in ggplot2 where 'size' was renamed to 'linewidth'
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
# Purpose: Create custom ggplot2 theme for publication-quality figures
theme_nature <- function(base_size = BASE_FONT_SIZE, base_family = FONT_FAMILY) {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(color = "black", family = base_family),
      plot.background  = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      
      axis.title.x = ggplot2::element_text(color = "black", margin = ggplot2::margin(t = 8)),
      axis.title.y = ggplot2::element_text(color = "black", margin = ggplot2::margin(r = 5)),
      
      axis.text.x  = ggplot2::element_text(color = "black", margin = ggplot2::margin(t = 6)),
      axis.text.y  = ggplot2::element_text(color = "black", margin = ggplot2::margin(r = 2)),
      
      axis.line  = element_line_lw(color = "black", linewidth = LW_AXIS),
      axis.ticks = element_line_lw(color = "black", linewidth = LW_AXIS),
      axis.ticks.length = grid::unit(2.2, "mm"),
      
      plot.margin = ggplot2::margin(2, 2, 2, 2),
      legend.position = "none"
    )
}

# ==============================================================================
# FUNCTION: read_table_auto
# ==============================================================================
# Purpose: Automatically detect delimiter and read table
read_table_auto <- function(path) {
  stopifnot(file.exists(path))
  first_line <- readLines(path, n = 1, warn = FALSE)
  
  if (grepl("\t", first_line)) {
    df <- readr::read_tsv(path, show_col_types = FALSE, progress = FALSE, comment = "#")
  } else if (grepl(",", first_line)) {
    df <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE, comment = "#")
  } else {
    df <- readr::read_table(path, show_col_types = FALSE, progress = FALSE, comment = "#")
  }
  
  names(df) <- trimws(names(df))
  df
}

# ==============================================================================
# FUNCTION: save_png
# ==============================================================================
# Purpose: Save ggplot object to high-resolution PNG
save_png <- function(p, filename, width_mm = PLOT_WIDTH_MM, height_mm = PLOT_HEIGHT_MM, res = PLOT_RES_DPI) {
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
# Purpose: Save ggplot object to vector PDF
save_pdf <- function(p, filename, width_mm = PLOT_WIDTH_MM, height_mm = PLOT_HEIGHT_MM) {
  ggplot2::ggsave(
    filename = filename,
    plot = p,
    width = width_mm,
    height = height_mm,
    units = "mm",
    device = "pdf",
    useDingbats = FALSE
  )
}

# ==============================================================================
# DATA PATH CONSTRUCTION
# ==============================================================================

# Base directory for shuffled modularity data
new_data_base_dir <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/shuffled_modularity"

# Function to construct shuffled modularity file path
get_shuffled_data_path <- function(cohort, simplex, session = SESSION, 
                                   peak = PEAK_THRESHOLD, purity = PURITY_THRESHOLD) {
  filename <- sprintf("shuffled_modularity_mean_with_delta_%s_%s_%s_peak_%d_purity_%d.csv",
                      simplex, cohort, session, peak, purity)
  file.path(new_data_base_dir, filename)
}

# Function to construct centrality file path
get_centrality_data_path <- function(cohort, session = SESSION) {
  base_path <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/mapper_node_features"
  filename <- sprintf("mapper_node_features_edge_%s_%s.csv", cohort, session)
  file.path(base_path, filename)
}

# ==============================================================================
# STATISTICAL RESULTS PATH CONSTRUCTION AND LOADING
# ==============================================================================

# Function to get shuffled modularity statistics path (main: all shuffle)
get_shuffled_stats_path <- function(peak_density_threshold = PEAK_DENSITY_THRESHOLD) {
  base_path <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/stat_shuffled_modularity"
  filename <- sprintf("stat_shuffled_modularity_ttest_all_%d.csv", peak_density_threshold)
  file.path(base_path, filename)
}

# Function to get matched random statistics path (supplementary)
get_shuffled_stats_matched_path <- function(peak_density_threshold = PEAK_DENSITY_THRESHOLD) {
  base_path <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/stat_shuffled_modularity"
  filename <- sprintf("stat_shuffled_modularity_ttest_matched_random_%d.csv", peak_density_threshold)
  file.path(base_path, filename)
}

# Function to get centrality statistics path
get_centrality_stats_path <- function() {
  "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/stat_centrality/stat_centrality.csv"
}

# Load pre-computed statistics
shuffled_stats_all <- read_table_auto(get_shuffled_stats_path())
shuffled_stats_matched <- NULL 

# Only attempt to load the matched stats file if the threshold is 90.
if (PEAK_DENSITY_THRESHOLD == 90) {
  message("Threshold is 90, attempting to load matched random stats file...")
  shuffled_stats_matched <- read_table_auto(get_shuffled_stats_matched_path())
}
centrality_stats <- read_table_auto(get_centrality_stats_path()) %>%
  dplyr::filter(analysis_type == "cohort_wide_t_test")

# ==============================================================================
# FUNCTION: normalize_centrality
# ==============================================================================
# Purpose: Z-score normalization
normalize_centrality <- function(x) {
  (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
}

# ==============================================================================
# FUNCTION: reshape_to_old_format
# ==============================================================================
# Purpose: Load separate simplex files and combine into old format
# Process: 1. Reads node, edge, triangle CSV files for given cohort
#          2. Combines them into single wide-format dataframe
#          3. Renames columns to match old naming convention
reshape_to_old_format <- function(cohort_id, 
                                  session = SESSION, 
                                  peak_threshold = PEAK_THRESHOLD, 
                                  purity_threshold = PURITY_THRESHOLD,
                                  peak_density_threshold = PEAK_DENSITY_THRESHOLD) {
  
  # Read all three simplex files for this cohort
  data_list <- list()
  
  for (sx in c("node", "edge", "triangle")) {
    file_path <- get_shuffled_data_path(cohort_id, sx, session, peak_threshold, purity_threshold)
    
    if (!file.exists(file_path)) {
      warning("Missing file: ", file_path)
      next
    }
    
    df <- tryCatch(
      read_table_auto(file_path),
      error = function(e) {
        warning("Failed to read: ", file_path, "\n  ", conditionMessage(e))
        return(NULL)
      }
    )
    
    if (is.null(df)) next
    data_list[[sx]] <- df
  }
  
  # Check we got all three
  if (length(data_list) != 3) {
    stop("Could not load all simplex files for cohort ", cohort_id, 
         " (session: ", session, ", peak: ", peak_threshold, 
         ", purity: ", purity_threshold, ")")
  }
  
  # Start with Subject column
  combined <- data_list[[1]] %>%
    dplyr::select(Subject)
  
  # Add columns for each simplex type with old naming convention
  for (sx in c("node", "edge", "triangle")) {
    df_sx <- data_list[[sx]]
    
    combined <- combined %>%
      dplyr::mutate(
        # Baseline conditions (no threshold suffix)
        !!paste0(sx, "_none") := df_sx$none,
        !!paste0(sx, "_all")  := df_sx$all,
        
        # High amplitude (peak-dense) columns
        !!paste0(sx, "_high_amp_", peak_density_threshold) := 
          df_sx[[paste0("peak_dense_", peak_density_threshold)]],
        
        # Matched baseline columns
        !!paste0(sx, "_matched_num_nodes_", peak_density_threshold) := 
          df_sx[[paste0("matched_random_", peak_density_threshold)]],
        
        # Delta columns (pre-computed)
        !!paste0(sx, "_high_amp_minus_none_", peak_density_threshold) := 
          df_sx[[paste0("peak_dense_minus_none_", peak_density_threshold)]]
      )
  }
  
  return(combined)
}

# ==============================================================================
# FUNCTION: plot_violin_box_fixedwidth
# ==============================================================================
# Purpose: Create violin+box plot with fixed width and positioning
plot_violin_box_fixedwidth <- function(df, x, y, fill, palette,
                                       ylab = NULL, xlab = NULL,
                                       add_hline0 = FALSE,
                                       slot_n_target = 3,
                                       violin_width = VIOLIN_WIDTH,
                                       box_width    = BOX_WIDTH,
                                       lw_violin    = LW_VIOLIN,
                                       lw_box       = LW_BOX,
                                       box_fatten   = BOX_FATTEN,
                                       ylim_fixed   = NULL,
                                       mean_dot_size = 2,
                                       mean_dot_color = "black") {
  
  x_vec    <- dplyr::pull(df, {{x}})
  y_vec    <- dplyr::pull(df, {{y}})
  fill_vec <- dplyr::pull(df, {{fill}})
  
  x_factor    <- if (is.factor(x_vec)) x_vec else factor(x_vec, levels = unique(x_vec))
  fill_factor <- if (is.factor(fill_vec)) fill_vec else factor(fill_vec, levels = unique(fill_vec))
  
  levels_x <- levels(x_factor)
  n_levels <- length(levels_x)
  
  slot_n <- max(slot_n_target, n_levels)
  shift  <- (slot_n - n_levels) / 2
  pos    <- seq_len(n_levels) + shift
  pos_map <- setNames(pos, levels_x)
  
  df2 <- df %>%
    dplyr::mutate(
      .x_factor    = x_factor,
      .fill_factor = fill_factor,
      .y_value     = as.numeric(y_vec),
      .x_pos       = as.numeric(pos_map[as.character(.x_factor)])
    ) %>%
    dplyr::filter(!is.na(.x_pos), !is.na(.y_value), !is.na(.fill_factor))
  
  df_means <- df2 %>%
    dplyr::group_by(.x_pos, .fill_factor) %>%
    dplyr::summarise(.mean_y = mean(.y_value, na.rm = TRUE), .groups = "drop")
  
  p <- ggplot2::ggplot(
    df2,
    ggplot2::aes(x = .x_pos, y = .y_value, fill = .fill_factor, group = .x_pos)
  )
  
  if ("linewidth" %in% names(formals(ggplot2::geom_violin))) {
    p <- p + ggplot2::geom_violin(
      trim = FALSE,
      scale = "width",
      width = violin_width,
      alpha = 0.95,
      color = "black",
      linewidth = lw_violin
    )
  } else {
    p <- p + ggplot2::geom_violin(
      trim = FALSE,
      scale = "width",
      width = violin_width,
      alpha = 0.95,
      color = "black",
      size = lw_violin
    )
  }
  
  if ("linewidth" %in% names(formals(ggplot2::geom_boxplot))) {
    p <- p + ggplot2::geom_boxplot(
      width = box_width,
      outlier.shape = NA,
      fill = "white",
      color = "black",
      linewidth = lw_box,
      fatten = box_fatten
    )
  } else {
    p <- p + ggplot2::geom_boxplot(
      width = box_width,
      outlier.shape = NA,
      fill = "white",
      color = "black",
      size = lw_box,
      fatten = box_fatten
    )
  }
  
  p <- p + ggplot2::geom_point(
    data = df_means,
    ggplot2::aes(x = .x_pos, y = .mean_y),
    inherit.aes = FALSE,
    color = mean_dot_color,
    size = mean_dot_size,
    shape = 16
  )
  
  p <- p +
    ggplot2::scale_fill_manual(values = palette) +
    ggplot2::scale_x_continuous(
      limits = c(0.5, slot_n + 0.5),
      breaks = pos,
      labels = levels_x,
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.06, 0.08))) +
    ggplot2::labs(x = xlab, y = ylab) +
    theme_nature() +
    ggplot2::coord_cartesian(clip = "off")
  
  if (add_hline0) {
    if ("linewidth" %in% names(formals(ggplot2::geom_hline))) {
      p <- p + ggplot2::geom_hline(
        yintercept = 0,
        linetype = "dashed",
        linewidth = LW_HLINE,
        color = "grey50",
        alpha = 0.9
      )
    } else {
      p <- p + ggplot2::geom_hline(
        yintercept = 0,
        linetype = "dashed",
        size = LW_HLINE,
        color = "grey50",
        alpha = 0.9
      )
    }
  }
  
  if (!is.null(ylim_fixed)) {
    p <- p + ggplot2::coord_cartesian(ylim = ylim_fixed, clip = "off")
  }
  
  p
}

# ==============================================================================
# FUNCTION: make_shuffled_modularity_simplex_plot
# ==============================================================================
# Purpose: Create violin+box plot for shuffled modularity data
# Process: 1. Constructs column names based on parameters
#          2. Reshapes data to long format
#          3. Looks up pre-computed significance from stats table
#          4. Creates plot with significance bars
make_shuffled_modularity_simplex_plot <- function(df, 
                                                  simplex = c("node","edge","triangle"),
                                                  cohort_id,
                                                  session = SESSION,
                                                  stats_table,
                                                  use_matched_all = FALSE, 
                                                  add_significance = TRUE,
                                                  sig_y_positions = NULL,
                                                  peak_density_threshold = PEAK_DENSITY_THRESHOLD) {
  simplex <- match.arg(simplex)
  
  simplex_color <- switch(
    simplex,
    node     = blue_light,
    edge     = blue_mid,
    triangle = blue_dark
  )
  
  # Construct column suffixes based on peak_density_threshold
  pct_suffix <- paste0("_", peak_density_threshold)
  
if (!use_matched_all) {
  cols    <- c(paste0(simplex, "_none"), 
               paste0(simplex, "_high_amp", pct_suffix), 
               paste0(simplex, "_all"))
  labels  <- c("No shuffle", "Peak-dense\nnodes\nshuffled", "All nodes\nshuffled")
} else {
  cols    <- c(paste0(simplex, "_none"), 
               paste0(simplex, "_high_amp", pct_suffix), 
               paste0(simplex, "_matched_num_nodes", pct_suffix))
  labels  <- c("No shuffle", "Peak-dense\nnodes\nshuffled", "Matched\nnum. of nodes\nshuffled")
}
  
  palette <- setNames(rep(simplex_color, length(labels)), labels)
  
  missing_cols <- setdiff(cols, names(df))
  if (length(missing_cols) > 0) {
    print(head(df))
    stop("Missing columns in shuffled-modularity file: ", paste(missing_cols, collapse = ", "))
  }
  
  df_long <- df %>%
    dplyr::select(dplyr::all_of(cols)) %>%
    tidyr::pivot_longer(cols = everything(), names_to = "cond_raw", values_to = "modularity") %>%
    dplyr::mutate(
      modularity = as.numeric(modularity),
      condition  = factor(cond_raw, levels = cols, labels = labels)
    ) %>%
    dplyr::filter(!is.na(modularity))
  
  # Look up pre-computed significance from stats table
  sig_segments <- NULL
  if (add_significance) {
    
    # Determine which test types to look for
    if (use_matched_all) {
      test_types <- c("peak_dense_minus_none", "peak_dense_minus_matched_random", "none_minus_matched_random")
    } else {
      test_types <- c("peak_dense_minus_none", "peak_dense_minus_all", "none_minus_all")
    }
    
    # Filter stats to current cohort, session, simplex
    panel_stats <- stats_table %>%
      dplyr::filter(
        cohort == cohort_id,
        session == !!session,
        simplex == !!simplex,
        test_type %in% test_types
      ) %>%
      dplyr::filter(significance_bonferroni != "0")  # Only significant ones
    
    if (nrow(panel_stats) > 0) {
      # Determine default y-positions if not provided
      if (is.null(sig_y_positions)) {
        if (!is.null(YLIM_SHUFFLED_MOD)) {
          y_range <- diff(YLIM_SHUFFLED_MOD)
          y_max <- YLIM_SHUFFLED_MOD[2]
        } else {
          y_max <- max(df_long$modularity, na.rm = TRUE)
          y_range <- y_max - min(df_long$modularity, na.rm = TRUE)
        }
        sig_y_positions <- c(
          y_max - 0.05 * y_range,  # Top bar (1-3)
          y_max - 0.12 * y_range,  # Middle bar (2-3)
          y_max - 0.19 * y_range   # Bottom bar (1-2)
        )
      }
      
      # Map test_type to bar position
      sig_list <- list()
      for (i in seq_len(nrow(panel_stats))) {
        row <- panel_stats[i, ]
        
        if (use_matched_all) {
          # Matched plot: positions 1=none, 2=peak_dense, 3=matched_random
          bar_data <- switch(
            row$test_type,
            
            "peak_dense_minus_none" = data.frame(
              x_start = 1 + 0.1,
              x_end = 2 - 0.1,
              y = sig_y_positions[3],
              sig_marker = row$significance_bonferroni
            ),
            
            "none_minus_matched_random" = data.frame(
              x_start = 1,
              x_end = 3,
              y = sig_y_positions[1],
              sig_marker = row$significance_bonferroni
            ),
            
            "peak_dense_minus_matched_random" = data.frame(
              x_start = 2 + 0.1,
              x_end = 3 - 0.1,
              y = sig_y_positions[2],
              sig_marker = row$significance_bonferroni
            ),
            
            NULL
          )
        } else {
          # Main plot: positions 1=none, 2=peak_dense, 3=all
          bar_data <- switch(
            row$test_type,
            
            "peak_dense_minus_none" = data.frame(
              x_start = 1 + 0.1,
              x_end = 2 - 0.1,
              y = sig_y_positions[3],
              sig_marker = row$significance_bonferroni
            ),
            
            "none_minus_all" = data.frame(
              x_start = 1,
              x_end = 3,
              y = sig_y_positions[1],
              sig_marker = row$significance_bonferroni
            ),
            
            "peak_dense_minus_all" = data.frame(
              x_start = 2 + 0.1,
              x_end = 3 - 0.1,
              y = sig_y_positions[2],
              sig_marker = row$significance_bonferroni
            ),
            
            NULL
          )
        }
        
        if (!is.null(bar_data)) {
          sig_list[[length(sig_list) + 1]] <- bar_data
        }
      }
      
      if (length(sig_list) > 0) {
        sig_segments <- dplyr::bind_rows(sig_list) %>%
          dplyr::mutate(x_mid = (x_start + x_end) / 2)
      }
    }
  }
  
  p <- plot_violin_box_fixedwidth(
    df_long,
    x = condition, y = modularity, fill = condition,
    palette = palette,
    ylab = "Quality of Modularity",
    xlab = NULL,
    slot_n_target = 3,
    ylim_fixed = YLIM_SHUFFLED_MOD
  ) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(lineheight = 0.95, color = "black"))
  
  # Add significance bars if any
  if (!is.null(sig_segments) && nrow(sig_segments) > 0) {
    if ("linewidth" %in% names(formals(ggplot2::geom_segment))) {
      p <- p + ggplot2::geom_segment(
        data = sig_segments,
        ggplot2::aes(x = x_start, xend = x_end, y = y, yend = y),
        inherit.aes = FALSE,
        color = "black",
        linewidth = 0.6
      )
    } else {
      p <- p + ggplot2::geom_segment(
        data = sig_segments,
        ggplot2::aes(x = x_start, xend = x_end, y = y, yend = y),
        inherit.aes = FALSE,
        color = "black",
        size = 0.6
      )
    }
    
    # Add significance markers (*, **, ***)
    p <- p + ggplot2::geom_text(
      data = sig_segments,
      ggplot2::aes(x = x_mid, y = y, label = sig_marker),
      inherit.aes = FALSE,
      vjust = -ASTERISK_VJUST,
      size = SIG_LABEL_SIZE,
      color = "black"
    )
  }
  
  p
}

# ==============================================================================
# FUNCTION: make_delta_modularity_plot
# ==============================================================================
# Purpose: Create violin+box plot for change in modularity across simplices
# Process: 1. Computes or retrieves delta values (peak_dense - baseline)
#          2. Looks up pre-computed pairwise significance between simplices
#          3. Creates plot with horizontal significance bars and y=0 line
# Notes:   NO vertical arrows (removed one-sample t-tests)
#          KEEPS horizontal bars comparing simplices to each other
make_delta_modularity_plot <- function(df, 
                                       cohort_id,
                                       session = SESSION,
                                       stats_table,
                                       use_matched_baseline = FALSE,
                                       add_significance = TRUE,
                                       peak_density_threshold = PEAK_DENSITY_THRESHOLD) {
  
  # Construct column suffixes
  pct_suffix <- paste0("_", peak_density_threshold)
  
  if (!use_matched_baseline) {
    wanted <- c(paste0("node_high_amp_minus_none", pct_suffix),
                paste0("edge_high_amp_minus_none", pct_suffix),
                paste0("triangle_high_amp_minus_none", pct_suffix))
    
    if (all(wanted %in% names(df))) {
      d <- df %>% dplyr::select(dplyr::all_of(wanted))
      names(d) <- c("Node","Edge","Triangle")
    } else {
      base_cols <- c(
        paste0("node_high_amp", pct_suffix), "node_none",
        paste0("edge_high_amp", pct_suffix), "edge_none",
        paste0("triangle_high_amp", pct_suffix), "triangle_none"
      )
      missing <- setdiff(base_cols, names(df))
      if (length(missing) > 0) {
        stop("Cannot compute deltas; missing columns: ", paste(missing, collapse = ", "))
      }
      d <- tibble::tibble(
        Node     = as.numeric(df[[paste0("node_high_amp", pct_suffix)]]) - as.numeric(df$node_none),
        Edge     = as.numeric(df[[paste0("edge_high_amp", pct_suffix)]]) - as.numeric(df$edge_none),
        Triangle = as.numeric(df[[paste0("triangle_high_amp", pct_suffix)]]) - as.numeric(df$triangle_none)
      )
    }
  } else {
    base_cols <- c(
      paste0("node_high_amp", pct_suffix), paste0("node_matched_num_nodes", pct_suffix),
      paste0("edge_high_amp", pct_suffix), paste0("edge_matched_num_nodes", pct_suffix),
      paste0("triangle_high_amp", pct_suffix), paste0("triangle_matched_num_nodes", pct_suffix)
    )
    missing <- setdiff(base_cols, names(df))
    if (length(missing) > 0) {
      stop("Cannot compute matched deltas; missing columns: ", paste(missing, collapse = ", "))
    }
    d <- tibble::tibble(
      Node     = as.numeric(df[[paste0("node_high_amp", pct_suffix)]]) - as.numeric(df[[paste0("node_matched_num_nodes", pct_suffix)]]),
      Edge     = as.numeric(df[[paste0("edge_high_amp", pct_suffix)]]) - as.numeric(df[[paste0("edge_matched_num_nodes", pct_suffix)]]),
      Triangle = as.numeric(df[[paste0("triangle_high_amp", pct_suffix)]]) - as.numeric(df[[paste0("triangle_matched_num_nodes", pct_suffix)]])
    )
  }

  df_long <- d %>%
    tidyr::pivot_longer(cols = everything(), names_to = "simplex", values_to = "delta_modularity") %>%
    dplyr::mutate(
      simplex = factor(simplex, levels = c("Node","Edge","Triangle")),
      delta_modularity = as.numeric(delta_modularity)
    ) %>%
    dplyr::filter(!is.na(delta_modularity))

  # Look up pre-computed pairwise significance (HORIZONTAL BARS)
  sig_segments <- NULL
  if (add_significance && !is.null(stats_table)) {
    
    # Filter to pairwise comparisons for this cohort/session
    panel_stats <- stats_table %>%
      dplyr::filter(
        cohort == cohort_id,
        session == !!session,
        test_type %in% c("paired_edge_vs_node", "paired_edge_vs_triangle", "paired_triangle_vs_node")
      ) %>%
      dplyr::filter(significance_bonferroni != "0")  # Only significant
    
    if (nrow(panel_stats) > 0) {
      # Calculate y-positions for horizontal bars (BELOW the plot, in negative space)
      if (!is.null(YLIM_DELTA_MOD)) {
        y_range <- diff(YLIM_DELTA_MOD)
        y_min <- YLIM_DELTA_MOD[1]
      } else {
        y_min <- min(df_long$delta_modularity, na.rm = TRUE)
        y_max <- max(df_long$delta_modularity, na.rm = TRUE)
        y_range <- y_max - y_min
      }
      
      # Position bars below the plot (in negative space if limits allow)
      y_pos_node_triangle <- y_min + 0.05 * y_range  # Lowest bar (widest span: 1-3)
      y_pos_edge_triangle <- y_min + 0.15 * y_range  # Middle bar (2-3)
      y_pos_node_edge     <- y_min + 0.15 * y_range  # Highest bar (1-2)
      
      # Map test types to bar positions
      sig_list <- list()
      for (i in seq_len(nrow(panel_stats))) {
        row <- panel_stats[i, ]
        
        bar_data <- switch(
          row$test_type,
          
          # Node (1) vs Edge (2)
          "paired_edge_vs_node" = data.frame(
            x_start = 1 + 0.1,
            x_end = 2 - 0.1,
            y = y_pos_node_edge,
            sig_marker = row$significance_bonferroni
          ),
          
          # Node (1) vs Triangle (3)
          "paired_triangle_vs_node" = data.frame(
            x_start = 1,
            x_end = 3,
            y = y_pos_node_triangle,
            sig_marker = row$significance_bonferroni
          ),
          
          # Edge (2) vs Triangle (3)
          "paired_edge_vs_triangle" = data.frame(
            x_start = 2 + 0.1,
            x_end = 3 - 0.1,
            y = y_pos_edge_triangle,
            sig_marker = row$significance_bonferroni
          ),
          
          NULL
        )
        
        if (!is.null(bar_data)) {
          sig_list[[length(sig_list) + 1]] <- bar_data
        }
      }
      
      if (length(sig_list) > 0) {
        sig_segments <- dplyr::bind_rows(sig_list) %>%
          dplyr::mutate(x_mid = (x_start + x_end) / 2)
      }
    }
  }
  
  # Create plot
  p <- plot_violin_box_fixedwidth(
    df_long,
    x = simplex, y = delta_modularity, fill = simplex,
    palette = pal_simplex,
    ylab = NULL,  # No y-axis label for delta plots
    xlab = NULL,
    add_hline0 = TRUE,  # KEEP horizontal dashed line at y=0
    slot_n_target = 3,
    ylim_fixed = YLIM_DELTA_MOD
  ) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(lineheight = 0.95, color = "black"))

  # Add HORIZONTAL significance bars (NO vertical arrows)
  if (!is.null(sig_segments) && nrow(sig_segments) > 0) {
    if ("linewidth" %in% names(formals(ggplot2::geom_segment))) {
      p <- p + ggplot2::geom_segment(
        data = sig_segments,
        ggplot2::aes(x = x_start, xend = x_end, y = y, yend = y),
        inherit.aes = FALSE,
        color = "black",
        linewidth = 0.6
      )
    } else {
      p <- p + ggplot2::geom_segment(
        data = sig_segments,
        ggplot2::aes(x = x_start, xend = x_end, y = y, yend = y),
        inherit.aes = FALSE,
        color = "black",
        size = 0.6
      )
    }
    
    # Add significance markers (*, **, ***)
    p <- p + ggplot2::geom_text(
      data = sig_segments,
      ggplot2::aes(x = x_mid, y = y, label = sig_marker),
      inherit.aes = FALSE,
      vjust = -ASTERISK_VJUST,
      size = SIG_LABEL_SIZE,
      color = "black"
    )
  }

  p
}

# ==============================================================================
# FUNCTION: make_within_task_centrality_plot
# ==============================================================================
# Purpose: Create centrality comparison plot for peak-dense vs other pure nodes
# Process: 1. Classifies pure nodes (purity >= threshold)
#          2. Calculates peak-dense threshold among pure nodes (percentile)
#          3. Classifies peak-dense nodes among pure nodes
#          4. Normalizes centrality (z-score)
#          5. Looks up pre-computed significance
#          6. Creates plot with significance bar
make_within_task_centrality_plot <- function(df,
                                             cohort_id,
                                             session = SESSION,
                                             stats_table,
                                             peak_threshold = PEAK_THRESHOLD,
                                             purity_threshold = PURITY_THRESHOLD,
                                             peak_density_threshold = PEAK_DENSITY_THRESHOLD,
                                             normalize = TRUE,
                                             add_significance = TRUE,
                                             sig_y_position = NULL) {
  
  message("\n=== DIAGNOSTIC: Input to make_within_task_centrality_plot ===")
  message("Cohort: ", cohort_id)
  message("Session: ", session)
  message("Peak threshold: ", peak_threshold)
  message("Purity threshold: ", purity_threshold)
  message("Peak density threshold: ", peak_density_threshold)
  
  message("\n=== Dataframe dimensions ===")
  message("Rows: ", nrow(df))
  message("Columns: ", ncol(df))
  
  message("\n=== All column names ===")
  print(names(df))
  
  
  
  # Construct column names dynamically
  amp_col <- paste0("amplitude_peak_density_peak_threshold_", peak_threshold)
  cent_col <- "mapper_stat_within_task_centrallity"
  purity_col <- "mapper_stat_node_purity"
  
  # Validate columns exist
  if (!amp_col %in% names(df)) {
    stop("Could not find amplitude column: ", amp_col)
  }
  if (!cent_col %in% names(df)) {
    stop("Could not find centrality column: ", cent_col)
  }
  if (!purity_col %in% names(df)) {
    stop("Could not find purity column: ", purity_col)
  }
  
  # STEP 1: Classify pure nodes (purity >= threshold)
  df_node_properties <- df %>%
    dplyr::mutate(
      is_pure_node = (.data[[purity_col]] >= purity_threshold / 100)
    )
  
  # Filter to pure nodes only
  df_node_properties <- df_node_properties %>%
    dplyr::filter(is_pure_node == TRUE)
  
  if (nrow(df_node_properties) == 0) {
    stop("No pure nodes found with purity >= ", purity_threshold)
  }
  
  # STEP 2: Calculate peak-dense threshold among PURE NODES ONLY
  amplitude_values <- df_node_properties[[amp_col]]
  amplitude_values <- amplitude_values[!is.na(amplitude_values)]
  
  if (length(amplitude_values) == 0) {
    stop("No valid amplitude values among pure nodes")
  }
  
  # Calculate the percentile threshold
  amplitude_threshold <- quantile(
    amplitude_values, 
    probs = peak_density_threshold / 100,
    na.rm = TRUE
  )
  
  message("Pure nodes: ", nrow(df_node_properties), " out of ", nrow(df))
  message("Peak-dense threshold (", peak_density_threshold, 
          "th percentile among pure nodes): ", round(amplitude_threshold, 4))
  
  # STEP 3: Classify peak-dense nodes among pure nodes
  df_node_properties <- df_node_properties %>%
    dplyr::mutate(
      is_peak_dense = (.data[[amp_col]] > amplitude_threshold)
    )
  
  # Print the classification results
  message("\n=== DIAGNOSTIC: After peak-dense classification ===")
  message("Total pure nodes: ", nrow(df_node_properties))
  message("Peak-dense (TRUE): ", sum(df_node_properties$is_peak_dense == TRUE, na.rm = TRUE))
  message("Not peak-dense (FALSE): ", sum(df_node_properties$is_peak_dense == FALSE, na.rm = TRUE))
  message("Peak-dense (NA): ", sum(is.na(df_node_properties$is_peak_dense)))
  
  # STEP 4: Normalize centrality if requested
  if (normalize) {
    df_node_properties <- df_node_properties %>%
      dplyr::mutate(
        !!cent_col := normalize_centrality(.data[[cent_col]])
      )
  }
  
  # STEP 5: Create plotting dataframe
  df_long <- df_node_properties %>%
    dplyr::mutate(
      centrality = as.numeric(.data[[cent_col]]),
      group = dplyr::case_when(
        is_peak_dense == TRUE ~ "Peak-dense\npure nodes",
        is_peak_dense == FALSE ~ "All other\npure nodes",
        TRUE ~ NA_character_
      )
    ) %>%
    dplyr::filter(!is.na(group), !is.na(centrality)) %>%
    dplyr::mutate(group = factor(group, levels = c("Peak-dense\npure nodes","All other\npure nodes")))
  
  n_peak_dense <- sum(df_long$group == "Peak-dense\npure nodes", na.rm = TRUE)
  n_other <- sum(df_long$group == "All other\npure nodes", na.rm = TRUE)
  message("Peak-dense pure nodes: ", n_peak_dense)
  message("Other pure nodes: ", n_other)
  
  # STEP 6: Look up pre-computed significance from stats table
  sig_segments <- NULL
  if (add_significance && !is.null(stats_table)) {
    
    # Filter to current cohort and session
    panel_stats <- stats_table %>%
      dplyr::filter(
        cohort == cohort_id,
        session == !!session,
        comparison == "peak_dense_nodes_vs_other_pure_nodes"
      )
    
    if (nrow(panel_stats) == 0) {
      warning("No centrality statistics found for cohort=", cohort_id, ", session=", session)
    } else {
      sig_marker <- panel_stats$significance_bonferroni[1]
      
      # Only add bar if significant (not "0")
      if (sig_marker != "0") {
        message("Centrality comparison significant: ", sig_marker)
        
        # Calculate y position
        if (is.null(sig_y_position)) {
          if (!is.null(YLIM_CENTRALITY)) {
            y_range <- diff(YLIM_CENTRALITY)
            y_max <- YLIM_CENTRALITY[2]
          } else {
            y_max <- max(df_long$centrality, na.rm = TRUE)
            y_range <- y_max - min(df_long$centrality, na.rm = TRUE)
          }
          sig_y_position <- y_max - 0.05 * y_range
        }
        
        sig_segments <- data.frame(
          x_start = 1.5,
          x_end = 2.5,
          y = sig_y_position,
          sig_marker = sig_marker,
          x_mid = 2.0
        )
      } else {
        message("Centrality comparison not significant")
      }
    }
  }
  
  # STEP 7: Create plot
  p <- plot_violin_box_fixedwidth(
    df_long,
    x = group, y = centrality, fill = group,
    palette = pal_centrality,
    ylab = "Normalized centrality",
    xlab = NULL,
    slot_n_target = 3,
    ylim_fixed = YLIM_CENTRALITY
  ) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(lineheight = 0.95, color = "black"))
  
  # Add significance bar if significant
  if (!is.null(sig_segments) && nrow(sig_segments) > 0) {
    if ("linewidth" %in% names(formals(ggplot2::geom_segment))) {
      p <- p + ggplot2::geom_segment(
        data = sig_segments,
        ggplot2::aes(x = x_start, xend = x_end, y = y, yend = y),
        inherit.aes = FALSE,
        color = "black",
        linewidth = 0.6
      )
    } else {
      p <- p + ggplot2::geom_segment(
        data = sig_segments,
        ggplot2::aes(x = x_start, xend = x_end, y = y, yend = y),
        inherit.aes = FALSE,
        color = "black",
        size = 0.6
      )
    }
    
    # Add significance marker (*, **, ***)
    p <- p + ggplot2::geom_text(
      data = sig_segments,
      ggplot2::aes(x = x_mid, y = y, label = sig_marker),
      inherit.aes = FALSE,
      vjust = -ASTERISK_VJUST,
      size = SIG_LABEL_SIZE,
      color = "black"
    )
  }
  
  p
}

# ==============================================================================
# LOAD AND RESHAPE DATA TO OLD FORMAT
# ==============================================================================

# Load data for both cohorts
shuffle_data_cohort_one <- reshape_to_old_format("one")
shuffle_data_cohort_two <- reshape_to_old_format("two")

message("Cohort one data loaded: ", nrow(shuffle_data_cohort_one), " rows, ", ncol(shuffle_data_cohort_one), " columns")
print(head(names(shuffle_data_cohort_one)))

message("Cohort two data loaded: ", nrow(shuffle_data_cohort_two), " rows, ", ncol(shuffle_data_cohort_two), " columns")
print(head(names(shuffle_data_cohort_two)))

# Create lookup table for plotting loop
shuffle_files <- tibble::tribble(
  ~cohort, ~direction, ~data_object,
  "one", "LR", "shuffle_data_cohort_one",
  "two", "LR", "shuffle_data_cohort_two"
)

saved_files <- character()

# ==============================================================================
# MAIN PLOTTING LOOP: SHUFFLED MODULARITY (continued)
# ==============================================================================

for (i in seq_len(nrow(shuffle_files))) {
  info <- shuffle_files[i, ]
  
  # Get data from pre-loaded object
  df <- get(info$data_object)

for (sx in c("node","edge","triangle")) {
  # Main plots (all shuffle)
  p_main <- make_shuffled_modularity_simplex_plot(
    df, 
    simplex = sx, 
    cohort_id = info$cohort,
    session = info$direction,
    stats_table = shuffled_stats_all,
    use_matched_all = FALSE,
    sig_y_positions = c(0.8, 0.7, 0.7),
    peak_density_threshold = PEAK_DENSITY_THRESHOLD
  )
  
  out_main_png <- file.path(out_dir, sprintf(
    "shuffled_modularity_%s_%s_%s_all_peak_%d_purity_%d_peak_density_%d.png",
    info$cohort, info$direction, sx, 
    PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
  ))
  out_main_pdf <- file.path(out_dir, sprintf(
    "shuffled_modularity_%s_%s_%s_all_peak_%d_purity_%d_peak_density_%d.pdf",
    info$cohort, info$direction, sx,
    PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
  ))
  
  save_png(p_main, out_main_png)
  save_pdf(p_main, out_main_pdf)
  saved_files <- c(saved_files, out_main_png, out_main_pdf)
  
  # Matched plots
  if (PEAK_DENSITY_THRESHOLD == 90) {
  p_matched <- make_shuffled_modularity_simplex_plot(
    df, 
    simplex = sx, 
    cohort_id = info$cohort,
    session = info$direction,
    stats_table = shuffled_stats_matched,
    use_matched_all = TRUE,
    sig_y_positions = c(0.8, 0.7, 0.7),
    peak_density_threshold = PEAK_DENSITY_THRESHOLD
  )
  
  out_matched_png <- file.path(out_dir, sprintf(
    "shuffled_modularity_%s_%s_%s_matched_random_peak_%d_purity_%d_peak_density_%d.png",
    info$cohort, info$direction, sx,
    PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
  ))
  out_matched_pdf <- file.path(out_dir, sprintf(
    "shuffled_modularity_%s_%s_%s_matched_random_peak_%d_purity_%d_peak_density_%d.pdf",
    info$cohort, info$direction, sx,
    PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
  ))
  
  save_png(p_matched, out_matched_png)
  save_pdf(p_matched, out_matched_pdf)
  saved_files <- c(saved_files, out_matched_png, out_matched_pdf)
  }
}

# Delta plots - peak_dense minus none
p_delta <- make_delta_modularity_plot(
  df, 
  cohort_id = info$cohort,
  session = info$direction,
  stats_table = shuffled_stats_all,
  use_matched_baseline = FALSE,
  add_significance = TRUE,
  peak_density_threshold = PEAK_DENSITY_THRESHOLD
)

out_delta_png <- file.path(out_dir, sprintf(
  "delta_modularity_peak_dense_minus_none_%s_%s_all_peak_%d_purity_%d_peak_density_%d.png",
  info$cohort, info$direction,
  PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
))
out_delta_pdf <- file.path(out_dir, sprintf(
  "delta_modularity_peak_dense_minus_none_%s_%s_all_peak_%d_purity_%d_peak_density_%d.pdf",
  info$cohort, info$direction,
  PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
))

save_png(p_delta, out_delta_png)
save_pdf(p_delta, out_delta_pdf)
saved_files <- c(saved_files, out_delta_png, out_delta_pdf)

# Delta plots - peak_dense minus matched_random
if (PEAK_DENSITY_THRESHOLD == 90) {
p_delta_matched <- make_delta_modularity_plot(
  df,
  cohort_id = info$cohort,
  session = info$direction,
  stats_table = shuffled_stats_matched,
  use_matched_baseline = TRUE,
  add_significance = TRUE,
  peak_density_threshold = PEAK_DENSITY_THRESHOLD
)

out_delta_matched_png <- file.path(out_dir, sprintf(
  "delta_modularity_peak_dense_minus_matched_random_%s_%s_matched_random_peak_%d_purity_%d_peak_density_%d.png",
  info$cohort, info$direction,
  PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
))
out_delta_matched_pdf <- file.path(out_dir, sprintf(
  "delta_modularity_peak_dense_minus_matched_random_%s_%s_matched_random_peak_%d_purity_%d_peak_density_%d.pdf",
  info$cohort, info$direction,
  PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
))

save_png(p_delta_matched, out_delta_matched_png)
save_pdf(p_delta_matched, out_delta_matched_pdf)
saved_files <- c(saved_files, out_delta_matched_png, out_delta_matched_pdf)
}
}
# ==============================================================================
# CENTRALITY PLOTS
# ==============================================================================

centrality_cohorts <- c("one", "two")

for (cohort in centrality_cohorts) {
  cent_path <- get_centrality_data_path(cohort, session = SESSION)
  
  message("DEBUG: Looking for file: ", cent_path)
  message("DEBUG: File exists? ", file.exists(cent_path))
  
  if (!file.exists(cent_path)) {
    warning("Missing centrality file (skipping): ", cent_path)
    next
  }
  
  df <- tryCatch(
    read_table_auto(cent_path),
    error = function(e) {
      warning("Failed to read centrality file: ", cent_path, "\n  ", conditionMessage(e))
      return(NULL)
    }
  )
  
  message("DEBUG: df is null? ", is.null(df))
  if (!is.null(df)) {
    message("DEBUG: df has ", nrow(df), " rows and ", ncol(df), " columns")
    message("DEBUG: Column names: ", paste(names(df)[1:min(10, ncol(df))], collapse = ", "))
  }
  
  if (is.null(df)) next
  
  message("\n", paste(rep("=", 60), collapse = ""))
  message("Processing centrality for cohort: ", cohort)
  message(paste(rep("=", 60), collapse = ""))
  
  p_cent <- make_within_task_centrality_plot(
    df,
    cohort_id = cohort,
    session = SESSION,
    stats_table = centrality_stats,
    peak_threshold = PEAK_THRESHOLD,
    purity_threshold = PURITY_THRESHOLD,
    peak_density_threshold = PEAK_DENSITY_THRESHOLD,
    normalize = TRUE,
    add_significance = TRUE,
    sig_y_position = NULL
  )
  
  out_cent_png <- file.path(out_dir, sprintf(
    "within_task_centrality_%s_%s_peak_%d_purity_%d_peak_density_%d.png",
    cohort, SESSION,
    PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
  ))
  out_cent_pdf <- file.path(out_dir, sprintf(
    "within_task_centrality_%s_%s_peak_%d_purity_%d_peak_density_%d.pdf",
    cohort, SESSION,
    PEAK_THRESHOLD, PURITY_THRESHOLD, PEAK_DENSITY_THRESHOLD
  ))
  
  save_png(p_cent, out_cent_png)
  save_pdf(p_cent, out_cent_pdf)
  saved_files <- c(saved_files, out_cent_png, out_cent_pdf)
  
  message("Saved: ", basename(out_cent_png))
  message("Saved: ", basename(out_cent_pdf))
}

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================

message("\n", paste(rep("=", 60), collapse = ""))
message("Done! All plots saved to: ", out_dir)
message("Peak density threshold: ", PEAK_DENSITY_THRESHOLD)
message("Total files generated: ", length(saved_files))
message(paste(rep("=", 60), collapse = ""))