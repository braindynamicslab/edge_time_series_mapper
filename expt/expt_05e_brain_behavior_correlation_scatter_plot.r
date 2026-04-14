# ---- fig2b_edge_vs_NEOFAC_C_OLS_cleancolors (x = z-scored modularity) ----
pkgs <- c("readr","dplyr","stringr","ggplot2","broom")
to_install <- pkgs[!pkgs %in% installed.packages()[,"Package"]]
if (length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

csv_path <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/brain_behavior_correlation_raw/stats_raw_features_all_both_schaefer100x7_edge_predicts_NEOFAC_C_controlledby_none.csv"

find_edge_col <- function(df) {
  # Note: The actual column name should be both_edge_modularity
  nms <- names(df)
  cand <- nms[grepl("edge", nms,  ignore.case = TRUE) & grepl("mod|q", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("edge_mod", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("^edge", nms, ignore.case = TRUE)]
  if (!length(cand)) stop("Couldn't find an edge modularity column.")
  cand[1]
}
find_neofac_c <- function(df) {
  nms <- names(df)
  cand <- nms[grepl("neo", nms, ignore.case = TRUE) & grepl("fac", nms, ignore.case = TRUE) & grepl("_c\\b|_cons|consc", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("neofac_c|conscientious", nms, ignore.case = TRUE)]
  if (!length(cand)) stop("Couldn't find NEOFAC_C column.")
  cand[1]
}

df <- readr::read_csv(csv_path, show_col_types = FALSE)
x_col <- find_edge_col(df); y_col <- find_neofac_c(df)

dat <- df |>
  dplyr::select(x_raw = all_of(x_col), y = all_of(y_col)) |>
  dplyr::filter(is.finite(x_raw), is.finite(y)) |>
  dplyr::mutate(
    x = as.numeric(scale(x_raw))   # <-- z-score edge modularity
  ) |>
  dplyr::select(x, y)

fit <- lm(y ~ x, data = dat)
st  <- broom::glance(fit); co <- broom::tidy(fit)
slope <- co$estimate[co$term=="x"]; pval <- co$p.value[co$term=="x"]
icpt  <- co$estimate[co$term=="(Intercept)"]; r2 <- st$r.squared; n <- nrow(dat)

# Significance asterisks
sig_label <- ""
if (pval < 0.001) {
  sig_label <- "***"
} else if (pval < 0.01) {
  sig_label <- "**"
} else if (pval < 0.05) {
  sig_label <- "*"
}

# Tunable parameter for asterisk x-position
asterisk_x <- 4.3
asterisk_y <- asterisk_x * slope + icpt
x_max <- 4.5

p_neoc <- ggplot(dat, aes(x, y)) +
  geom_point(alpha = 0.35, size = 0.9) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE,
              color = "#1b4f72", fill = "#aed6f1", alpha = 0.4, linewidth = 1) +
  coord_cartesian(xlim = c(NA, x_max)) +  # Zoom to x max = x_max
  labs(
    title = "NEO Conscientiousness vs. Edge modularity",
    x = "Edge modularity",
    y = "Conscientiousness"
  ) +
  theme_classic(base_size = 10) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.ticks.length = unit(3, "pt"),
    axis.line = element_line(linewidth = 0.4)
  )

# Add significance asterisk if significant
if (sig_label != "") {
  p_neoc <- p_neoc + 
    annotate("text", x = asterisk_x, y = asterisk_y, label = sig_label, 
             size = 8, color = "#aed6f1")
}

p_neoc

# Create output directory if it doesn't exist
output_dir <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/plot_brain_behavior_correlation"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save as PNG
ggsave(file.path(output_dir, "plot_brain_behavior_correlation_scatter_edge_modularity_vs_NEOFAC_C.png"), 
       p_neoc, width = 85, height = 85, units = "mm", dpi = 600, bg = "white")

# Save as PDF
ggsave(file.path(output_dir, "plot_brain_behavior_correlation_scatter_edge_modularity_vs_NEOFAC_C.pdf"), 
       p_neoc, width = 85, height = 85, units = "mm", dpi = 600, bg = "white")

#externalizing
# ---- fig2b_edge_vs_ASR_Extn_T_OLS_cleancolors (x = z-scored modularity) ----
pkgs <- c("readr","dplyr","stringr","ggplot2","broom")
to_install <- pkgs[!pkgs %in% installed.packages()[,"Package"]]
if (length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

csv_path <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/brain_behavior_correlation_raw/stats_raw_features_all_both_schaefer100x7_edge_predicts_ASR_Extn_T_controlledby_none.csv"

find_edge_col <- function(df) {
  # Note: The actual column name should be both_edge_modularity
  nms <- names(df)
  cand <- nms[grepl("edge", nms,  ignore.case = TRUE) & grepl("mod|q", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("edge_mod", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("^edge", nms, ignore.case = TRUE)]
  if (!length(cand)) stop("Couldn't find an edge modularity column.")
  cand[1]
}
find_asr_extn <- function(df) {
  nms <- names(df)
  cand <- nms[grepl("asr", nms, ignore.case = TRUE) & grepl("extn|extern", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("extn", nms, ignore.case = TRUE)]
  if (!length(cand)) stop("Couldn't find ASR_Extn_T column.")
  cand[1]
}

df <- readr::read_csv(csv_path, show_col_types = FALSE)
x_col <- find_edge_col(df); y_col <- find_asr_extn(df)

dat <- df |>
  dplyr::select(x_raw = all_of(x_col), y = all_of(y_col)) |>
  dplyr::filter(is.finite(x_raw), is.finite(y)) |>
  dplyr::mutate(
    x = as.numeric(scale(x_raw))   # <-- z-score edge modularity
  ) |>
  dplyr::select(x, y)

fit <- lm(y ~ x, data = dat)
st  <- broom::glance(fit); co <- broom::tidy(fit)
slope <- co$estimate[co$term=="x"]; pval <- co$p.value[co$term=="x"]
icpt  <- co$estimate[co$term=="(Intercept)"]; r2 <- st$r.squared; n <- nrow(dat)

# Significance asterisks
sig_label <- ""
if (pval < 0.001) {
  sig_label <- "***"
} else if (pval < 0.01) {
  sig_label <- "**"
} else if (pval < 0.05) {
  sig_label <- "*"
}

# Tunable parameter for asterisk x-position
asterisk_x <- 4.3
asterisk_y <- asterisk_x * slope + icpt
x_max <- 4.5

p_extn <- ggplot(dat, aes(x, y)) +
  geom_point(alpha = 0.35, size = 0.9) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE,
              color = "#1b4f72", fill = "#aed6f1", alpha = 0.4, linewidth = 1) +
  coord_cartesian(xlim = c(NA, x_max)) +  # Zoom to x max = x_max
  labs(
    title = "Externalizing vs. Edge modularity",
    x = "Edge modularity",
    y = "Externalizing"
  ) +
  theme_classic(base_size = 10) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.ticks.length = unit(3, "pt"),
    axis.line = element_line(linewidth = 0.4)
  )

# Add significance asterisk if significant
if (sig_label != "") {
  p_extn <- p_extn + 
    annotate("text", x = asterisk_x, y = asterisk_y, label = sig_label, 
             size = 8, color = "#aed6f1")
}

p_extn

# Create output directory if it doesn't exist
output_dir <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/plot_brain_behavior_correlation"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save as PNG
ggsave(file.path(output_dir, "plot_brain_behavior_correlation_scatter_edge_modularity_vs_ASR_Extn_T.png"), 
       p_extn, width = 85, height = 85, units = "mm", dpi = 600, bg = "white")

# Save as PDF
ggsave(file.path(output_dir, "plot_brain_behavior_correlation_scatter_edge_modularity_vs_ASR_Extn_T.pdf"), 
       p_extn, width = 85, height = 85, units = "mm", dpi = 600, bg = "white")

#internalizing
# ---- fig2b_edge_vs_ASR_Intn_T_OLS_cleancolors (x = z-scored modularity) ----
pkgs <- c("readr","dplyr","stringr","ggplot2","broom")
to_install <- pkgs[!pkgs %in% installed.packages()[,"Package"]]
if (length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

csv_path <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/brain_behavior_correlation_raw/stats_raw_features_all_both_schaefer100x7_edge_predicts_ASR_Intn_T_controlledby_none.csv"

find_edge_col <- function(df) {
  # Note: The actual column name should be both_edge_modularity
  nms <- names(df)
  cand <- nms[grepl("edge", nms,  ignore.case = TRUE) & grepl("mod|q", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("edge_mod", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("^edge", nms, ignore.case = TRUE)]
  if (!length(cand)) stop("Couldn't find an edge modularity column.")
  cand[1]
}
find_asr_intn <- function(df) {
  nms <- names(df)
  cand <- nms[grepl("asr", nms, ignore.case = TRUE) & grepl("intn|intern|internal", nms, ignore.case = TRUE)]
  if (length(cand) == 0) cand <- nms[grepl("asr_intn_t|asr_internalizing", nms, ignore.case = TRUE)]
  if (!length(cand)) stop("Couldn't find ASR_Intn_T column.")
  cand[1]
}

df <- readr::read_csv(csv_path, show_col_types = FALSE)
x_col <- find_edge_col(df); y_col <- find_asr_intn(df)

dat <- df |>
  dplyr::select(x_raw = all_of(x_col), y = all_of(y_col)) |>
  dplyr::filter(is.finite(x_raw), is.finite(y)) |>
  dplyr::mutate(
    x = as.numeric(scale(x_raw))   # <-- z-score edge modularity
  ) |>
  dplyr::select(x, y)

fit <- lm(y ~ x, data = dat)
st  <- broom::glance(fit); co <- broom::tidy(fit)
slope <- co$estimate[co$term=="x"]; pval <- co$p.value[co$term=="x"]
icpt  <- co$estimate[co$term=="(Intercept)"]; r2 <- st$r.squared; n <- nrow(dat)

# Significance asterisks
sig_label <- ""
if (pval < 0.001) {
  sig_label <- "***"
} else if (pval < 0.01) {
  sig_label <- "**"
} else if (pval < 0.05) {
  sig_label <- "*"
}

# Tunable parameter for asterisk x-position
asterisk_x <- 4.3
asterisk_y <- asterisk_x * slope + icpt
x_max <- 4.5

p_intn <- ggplot(dat, aes(x, y)) +
  geom_point(alpha = 0.35, size = 0.9) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE,
              color = "#1b4f72", fill = "#aed6f1", alpha = 0.4, linewidth = 1) +
  coord_cartesian(xlim = c(NA, x_max)) +  # Zoom to x max = x_max
  labs(
    title = "Internalizing vs. Edge modularity",
    x = "Edge modularity",
    y = "Internalizing"
  ) +
  theme_classic(base_size = 10) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.ticks.length = unit(3, "pt"),
    axis.line = element_line(linewidth = 0.4)
  )

# Add significance asterisk if significant
if (sig_label != "") {
  p_intn <- p_intn + 
    annotate("text", x = asterisk_x, y = asterisk_y, label = sig_label, 
             size = 8, color = "#aed6f1")
}

p_intn

# Create output directory if it doesn't exist
output_dir <- "/Users/siuc/Documents/GitHub/edge_time_series_mapper/data_pipeline/plot_brain_behavior_correlation"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save as PNG
ggsave(file.path(output_dir, "plot_brain_behavior_correlation_scatter_edge_modularity_vs_ASR_Intn_T.png"), 
       p_intn, width = 85, height = 85, units = "mm", dpi = 600, bg = "white")

# Save as PDF
ggsave(file.path(output_dir, "plot_brain_behavior_correlation_scatter_edge_modularity_vs_ASR_Intn_T.pdf"), 
       p_intn, width = 85, height = 85, units = "mm", dpi = 600, bg = "white")