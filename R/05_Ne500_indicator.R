# ============================================================
# 05_Ne500_indicator.R
# Calculate the Ne500 indicator from population and species-
# level census data, with transboundary adjustments and
# Ne/Nc conversions.
# Requires: kobo.cleaned from 02_quality_checks.R
# ============================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(rstatix)

# ----------------------------------------------------------
# 5.1 Extract taxa with population size data
# ----------------------------------------------------------

Ne500_data <- kobo.cleaned %>%
  mutate(popsize_data = tolower(popsize_data)) %>%
  filter(popsize_data %in% c("yes", "data_for_species"))

Ne500_data %>% count(popsize_data)

# ----------------------------------------------------------
# 5.2 Census data for species as a whole
# ----------------------------------------------------------

Ne500_sp <- Ne500_data %>%
  filter(tolower(popsize_data) == "data_for_species")

Ne500_sp %>% count(nc_type_sp)

range_conversion <- function(x) {
  dplyr::case_when(
    x == "more_5000_bymuch"    ~ 10000,
    x == "more_5000"           ~ 5500,
    x == "less_5000_bymuch"    ~ 500,
    x == "less_5000"           ~ 4500,
    x == "range_includes_5000" ~ 5001,
    TRUE                       ~ NA_real_
  )
}

Ne500_sp <- Ne500_sp %>%
  mutate(
    nc_sp_range_value = range_conversion(nc_range_sp),
    sp_census_value   = coalesce(nc_point_sp, nc_sp_range_value)
  )

Ne500_sp %>%
  select(taxon, nc_type_sp, nc_point_sp, nc_range_sp, nc_sp_range_value, sp_census_value)

# 5.2.1 Transboundary adjustment for species-level data
Ne500_sp <- Ne500_sp %>%
  mutate(
    sp_census_adjusted = case_when(
      national_endemic == "no" &
      popsize_data == "data_for_species" &
      sp_whole_or_part == "only_sa" ~ sp_census_value / (sa_percent / 100),
      TRUE ~ sp_census_value
    ),
    nc_adjusted = if_else(sp_census_adjusted != sp_census_value, "Nc_expanded", "Nc_not_expanded")
  )

Ne500_sp %>%
  select(taxon, national_endemic, sp_whole_or_part, nc_point_sp, nc_range_sp,
         nc_sp_range_value, sp_census_value, sp_census_adjusted, nc_adjusted)

# 5.2.2 Convert Nc to Ne using three ratios
Ne500_sp <- Ne500_sp %>%
  mutate(
    sp_Ne_from_Nc_0.1 = sp_census_adjusted * 0.1,
    sp_Ne_from_Nc_0.2 = sp_census_adjusted * 0.2,
    sp_Ne_from_Nc_0.3 = sp_census_adjusted * 0.3
  )

Ne500_sp %>%
  select(taxon, nc_type_sp, national_endemic, sp_whole_or_part, sp_census_adjusted,
         sp_Ne_from_Nc_0.1, sp_Ne_from_Nc_0.2, sp_Ne_from_Nc_0.3,
         Taxonomic_Order, realm, national_endemic,
         Previous_National_Red_List_Category, Current_National_Red_List_Category,
         IUCN_habitat, species_range)

# 5.2.2.1 Species-level taxa with Ne < 500
lowNe_sp <- Ne500_sp %>%
  filter(sp_Ne_from_Nc_0.1 < 500)

lowNe_sp %>%
  select(taxon, sp_Ne_from_Nc_0.1, sp_Ne_from_Nc_0.2, sp_Ne_from_Nc_0.3,
         Taxonomic_Order, realm, endemic_status,
         Previous_National_Red_List_Category, Current_National_Red_List_Category,
         IUCN_habitat, species_range)

lowNe_sp <- lowNe_sp %>%
  mutate(
    sp_indicator_0.1 = ifelse(!is.na(sp_Ne_from_Nc_0.1) & sp_Ne_from_Nc_0.1 > 500, 1, 0),
    sp_indicator_0.2 = ifelse(!is.na(sp_Ne_from_Nc_0.2) & sp_Ne_from_Nc_0.2 > 500, 1, 0),
    sp_indicator_0.3 = ifelse(!is.na(sp_Ne_from_Nc_0.3) & sp_Ne_from_Nc_0.3 > 500, 1, 0)
  )

lowNe_sp %>%
  select(taxon, taxonomic_group, sp_census_adjusted,
         sp_Ne_from_Nc_0.1, sp_indicator_0.1, sp_indicator_0.2, sp_indicator_0.3)

# ----------------------------------------------------------
# 5.3 Census data for individual populations
# ----------------------------------------------------------

Ne500_pop <- Ne500_data %>%
  filter(tolower(popsize_data) == "yes")

Ne500_pop %>%
  count(endemic_status, ne_pops_exists, nc_pops_exists, sort = TRUE)

# Define population-level column vectors
Nc_type_cols       <- paste0("NcType_pop", 1:25)
Nc_point_cols      <- paste0("NcPoint_pop", 1:25)
Nc_range_cols      <- paste0("NcRange_pop", 1:25)
transboundary_cols <- paste0("transboundary_pop", 1:25)
percent_cols       <- paste0("percent_pop", 1:25)

# Convert Nc range to numeric for each population
Ne500_pop <- Ne500_data %>%
  filter(popsize_data == "yes") %>%
  mutate(across(all_of(Nc_range_cols), ~ range_conversion(.x), .names = "{.col}_num"))

Ne500_pop %>%
  select(taxon, starts_with("NcType_pop"), starts_with("NcRange_pop"), ends_with("_num"))

# Combine point and range into census_pop[i] per population
for (i in 1:25) {
  point_col     <- Nc_point_cols[i]
  range_num_col <- paste0(Nc_range_cols[i], "_num")
  census_col    <- paste0("census_pop", i)
  Ne500_pop <- Ne500_pop %>%
    mutate("{census_col}" := coalesce(.data[[point_col]], .data[[range_num_col]]))
}

Ne500_pop %>%
  select(taxon, starts_with("NcType_pop"), starts_with("NcRange_pop"),
         ends_with("_num"), starts_with("census_pop"))

# 5.3.1 Transboundary adjustment per population
whole_or_part_cols <- paste0("whole_or_part_pop", 1:25)

for (i in 1:25) {
  census_col        <- paste0("census_pop", i)
  adjusted_col      <- paste0("census_adjusted_pop", i)
  transboundary_col <- transboundary_cols[i]
  percent_col       <- percent_cols[i]
  whole_or_part_col <- whole_or_part_cols[i]

  Ne500_pop <- Ne500_pop %>%
    mutate(
      "{adjusted_col}" := case_when(
        .data[[transboundary_col]] == "yes_transboundary" &
        .data[[whole_or_part_col]] == "only_sa" &
        !is.na(.data[[percent_col]]) &
        .data[[percent_col]] > 0
        ~ .data[[census_col]] / (.data[[percent_col]] / 100),
        TRUE ~ .data[[census_col]]
      )
    )
}

# Sanity check: verify adjustment logic
Ne500_pop %>%
  filter(taxon == "Balaenoptera musculus intermedia") %>%
  select(taxon, starts_with("census_pop"), starts_with("percent_pop"),
         starts_with("whole_or_parts_pop"), starts_with("census_adjusted_pop"))

Ne500_pop %>%
  select(taxon, transboundary_pop1, whole_or_part_pop1, percent_pop1, census_pop1, census_adjusted_pop1) %>%
  mutate(adjusted_applied = if_else(census_pop1 != census_adjusted_pop1, TRUE, FALSE))

# 5.3.2 Convert population Nc to Ne
for (i in 1:25) {
  adjusted_col <- paste0("census_adjusted_pop", i)
  Ne500_pop <- Ne500_pop %>%
    mutate(
      "{paste0('pop_Ne_from_Nc_0.1_', i)}" := .data[[adjusted_col]] * 0.1,
      "{paste0('pop_Ne_from_Nc_0.2_', i)}" := .data[[adjusted_col]] * 0.2,
      "{paste0('pop_Ne_from_Nc_0.3_', i)}" := .data[[adjusted_col]] * 0.3
    )
}

Ne500_pop %>%
  select(taxon, census_adjusted_pop1, pop_Ne_from_Nc_0.1_1, pop_Ne_from_Nc_0.2_1, pop_Ne_from_Nc_0.3_1) %>%
  head()

# ----------------------------------------------------------
# 5.4 Prioritise Ne data over Nc-derived estimates
# ----------------------------------------------------------

for (i in 1:25) {
  census_col <- paste0("census_adjusted_pop", i)
  Ne_col     <- paste0("Ne_pop", i)
  Ne01_col   <- paste0("final_Ne_pop", i, "_0.1")
  Ne02_col   <- paste0("final_Ne_pop", i, "_0.2")
  Ne03_col   <- paste0("final_Ne_pop", i, "_0.3")

  Ne500_pop <- Ne500_pop %>%
    mutate(
      "{Ne01_col}" := coalesce(.data[[Ne_col]], .data[[census_col]] * 0.1),
      "{Ne02_col}" := coalesce(.data[[Ne_col]], .data[[census_col]] * 0.2),
      "{Ne03_col}" := coalesce(.data[[Ne_col]], .data[[census_col]] * 0.3)
    )
}

Ne500_pop %>%
  select(taxon, census_adjusted_pop1, Ne_pop1,
         final_Ne_pop1_0.1, final_Ne_pop1_0.2, final_Ne_pop1_0.3)

taxa_pop_both <- Ne500_pop %>%
  select(taxon, matches("^Ne_pop\\d+$"), matches("^census_adjusted_pop\\d+$")) %>%
  pivot_longer(
    cols = -taxon,
    names_to = c(".value", "pop"),
    names_pattern = "(Ne_pop|census_adjusted_pop)(\\d+)"
  ) %>%
  filter(!is.na(Ne_pop) & !is.na(census_adjusted_pop)) %>%
  arrange(taxon, as.integer(pop))

taxa_pop_both

# ----------------------------------------------------------
# 5.5 Transform to long format for indicator calculation
# ----------------------------------------------------------

Ne500_long <- Ne500_pop %>%
  pivot_longer(
    cols = starts_with("final_Ne_pop"),
    names_to = c("pop_id", "Ne_ratio"),
    names_pattern = "final_Ne_pop(\\d+)_(0\\.\\d+)",
    values_to = "Ne_value"
  ) %>%
  filter(!is.na(Ne_value))

Ne500_long %>%
  select(taxon, Ne_ratio, Ne_value, national_endemic, everything())

# Add extinct populations as Ne = 0
extinct_pops_long <- Ne500_long %>%
  distinct(taxon, Ne_ratio, taxonomic_group, Taxonomic_Order, endemic_status,
           Previous_National_Red_List_Category, Current_National_Red_List_Category,
           IUCN_habitat, species_range, n_extinct_populations) %>%
  filter(!is.na(n_extinct_populations), n_extinct_populations > 0) %>%
  uncount(n_extinct_populations, .remove = FALSE) %>%
  mutate(Ne_value = 0, pop_status = "extinct")

Ne500_long_full <- Ne500_long %>%
  mutate(pop_status = "extant") %>%
  bind_rows(extinct_pops_long)

# Summarise per taxon
Ne500_per_taxa <- Ne500_long_full %>%
  group_by(taxon, Ne_ratio) %>%
  summarise(
    taxonomic_group                    = first(taxonomic_group),
    Taxonomic_Order                    = first(Taxonomic_Order),
    endemic_status                     = first(endemic_status),
    realm                              = first(realm),
    Previous_National_Red_List_Category = first(Previous_National_Red_List_Category),
    Current_National_Red_List_Category  = first(Current_National_Red_List_Category),
    IUCN_habitat                       = first(IUCN_habitat),
    species_range                      = first(species_range),
    n_pops                             = n(),
    n_above_500                        = sum(Ne_value >= 500, na.rm = TRUE),
    prop_above_500                     = n_above_500 / n_pops,
    .groups = "drop"
  )

Ne500_per_taxa

# Sanity check: effect of extinct populations
Ne500_per_taxa_no_extinct <- Ne500_long %>%
  group_by(taxon, Ne_ratio) %>%
  summarise(
    n_pops_no_extinct         = n(),
    n_above_500_no_extinct    = sum(Ne_value >= 500, na.rm = TRUE),
    prop_above_500_no_extinct = n_above_500_no_extinct / n_pops_no_extinct,
    .groups = "drop"
  )

Ne500_per_taxa_with_extinct <- Ne500_long_full %>%
  group_by(taxon, Ne_ratio) %>%
  summarise(
    n_pops_with_extinct         = n(),
    n_above_500_with_extinct    = sum(Ne_value >= 500, na.rm = TRUE),
    prop_above_500_with_extinct = n_above_500_with_extinct / n_pops_with_extinct,
    .groups = "drop"
  )

Ne500_comparison <- Ne500_per_taxa_no_extinct %>%
  left_join(Ne500_per_taxa_with_extinct, by = c("taxon", "Ne_ratio")) %>%
  mutate(
    delta_prop        = prop_above_500_with_extinct - prop_above_500_no_extinct,
    indicator_changed = prop_above_500_with_extinct != prop_above_500_no_extinct
  )

Ne500_comparison %>%
  summarise(n_taxa_total = n_distinct(taxon), n_taxa_changed = sum(indicator_changed, na.rm = TRUE))

Ne500_comparison %>%
  filter(indicator_changed) %>%
  summarise(
    mean_change   = mean(delta_prop, na.rm = TRUE),
    median_change = median(delta_prop, na.rm = TRUE),
    min_change    = min(delta_prop, na.rm = TRUE),
    max_change    = max(delta_prop, na.rm = TRUE)
  )

Ne500_comparison %>%
  filter(indicator_changed) %>%
  arrange(delta_prop) %>%
  select(taxon, Ne_ratio, n_pops_no_extinct, n_pops_with_extinct,
         prop_above_500_no_extinct, prop_above_500_with_extinct, delta_prop)

taxa_with_extinct <- kobo.cleaned %>%
  filter(n_extinct_populations > 0) %>%
  distinct(taxon, n_extinct_populations)

taxa_in_pop_indicator <- Ne500_long %>% distinct(taxon)

taxa_with_extinct %>%
  mutate(in_indicator = taxon %in% taxa_in_pop_indicator$taxon)

# Pivot wide for merging
Ne500_per_taxa_wide <- Ne500_per_taxa %>%
  pivot_wider(
    id_cols = c(taxon, taxonomic_group, endemic_status, Taxonomic_Order, realm,
                Previous_National_Red_List_Category, Current_National_Red_List_Category,
                IUCN_habitat, species_range),
    names_from  = Ne_ratio,
    values_from = prop_above_500,
    names_prefix = "pop_indicator_"
  )

Ne500_per_taxa_wide

# Combine population and species-level datasets
combined_Ne500_indicators <- bind_rows(
  Ne500_per_taxa_wide,
  lowNe_sp %>%
    select(taxon, taxonomic_group, endemic_status, Taxonomic_Order, realm,
           Previous_National_Red_List_Category, Current_National_Red_List_Category,
           IUCN_habitat, species_range,
           sp_indicator_0.1, sp_indicator_0.2, sp_indicator_0.3)
) %>%
  mutate(
    indicator_0.1 = coalesce(sp_indicator_0.1, pop_indicator_0.1),
    indicator_0.2 = coalesce(sp_indicator_0.2, pop_indicator_0.2),
    indicator_0.3 = coalesce(sp_indicator_0.3, pop_indicator_0.3)
  )

combined_Ne500_indicators

# ----------------------------------------------------------
# 5.6 National Ne500 indicator
# ----------------------------------------------------------

avg_Ne500_by_taxonomic_group <- combined_Ne500_indicators %>%
  group_by(taxonomic_group) %>%
  summarise(
    n_taxa            = n(),
    avg_indicator_0.1 = mean(indicator_0.1, na.rm = TRUE),
    sd_indicator_0.1  = sd(indicator_0.1, na.rm = TRUE),
    se_indicator_0.1  = sd(indicator_0.1, na.rm = TRUE) / sqrt(n()),
    avg_indicator_0.2 = mean(indicator_0.2, na.rm = TRUE),
    sd_indicator_0.2  = sd(indicator_0.2, na.rm = TRUE),
    se_indicator_0.2  = sd(indicator_0.2, na.rm = TRUE) / sqrt(n()),
    avg_indicator_0.3 = mean(indicator_0.3, na.rm = TRUE),
    sd_indicator_0.3  = sd(indicator_0.3, na.rm = TRUE),
    se_indicator_0.3  = sd(indicator_0.3, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

avg_Ne500_by_taxonomic_group

# ----------------------------------------------------------
# 5.6.x Statistical tests by Threat Status
# ----------------------------------------------------------

kruskal_0.1_threat <- combined_Ne500_indicators %>%
  kruskal_test(indicator_0.1 ~ Current_National_Red_List_Category)
kruskal_0.1_threat

kruskal_0.2_threat <- combined_Ne500_indicators %>%
  kruskal_test(indicator_0.2 ~ Current_National_Red_List_Category)
kruskal_0.2_threat

kruskal_0.3_threat <- combined_Ne500_indicators %>%
  kruskal_test(indicator_0.3 ~ Current_National_Red_List_Category)
kruskal_0.3_threat

dunn_0.1_threat <- combined_Ne500_indicators %>%
  dunn_test(indicator_0.1 ~ Current_National_Red_List_Category, p.adjust.method = "holm")
write.csv(dunn_0.1_threat, "Dunn_Ne500_0.1_threat.csv")

dunn_0.2_threat <- combined_Ne500_indicators %>%
  dunn_test(indicator_0.2 ~ Current_National_Red_List_Category, p.adjust.method = "holm")
write.csv(dunn_0.2_threat, "Dunn_Ne500_0.2_threat.csv")

dunn_0.3_threat <- combined_Ne500_indicators %>%
  dunn_test(indicator_0.3 ~ Current_National_Red_List_Category, p.adjust.method = "holm")
write.csv(dunn_0.3_threat, "Dunn_Ne500_0.3_threat.csv")

proportion_low_indicator_RL <- combined_Ne500_indicators %>%
  filter(!is.na(Current_National_Red_List_Category), !is.na(indicator_0.1)) %>%
  group_by(Current_National_Red_List_Category) %>%
  summarise(
    n_taxa          = n(),
    n_below_0.25    = sum(indicator_0.1 < 0.25, na.rm = TRUE),
    prop_below_0.25 = n_below_0.25 / n_taxa,
    .groups = "drop"
  )

proportion_low_indicator_RL

taxa_low_indicator_RL <- combined_Ne500_indicators %>%
  filter(
    Current_National_Red_List_Category %in% c(
      "least_concern__lc", "near_threatened__nt", "vulnerable__vu", "data_deficient__dd"
    ),
    !is.na(indicator_0.3),
    indicator_0.3 < 0.75
  ) %>%
  select(taxon, Current_National_Red_List_Category, indicator_0.3)

taxa_low_indicator_RL %>% arrange(Current_National_Red_List_Category)
write.csv(taxa_low_indicator_RL, "Table_S18_LowNe500_RL.csv", row.names = FALSE)

# ----------------------------------------------------------
# 5.6.x Visualisations — Ne500 by Threat Status
# ----------------------------------------------------------

set.seed(123)

iucn_levels <- c(
  "regionally_extinct__re", "critically_endangered__cr", "endangered__en",
  "vulnerable__vu", "near_threatened__nt", "least_concern__lc", "data_deficient__dd"
)

iucn_labels <- c(
  "regionally_extinct__re" = "RE", "critically_endangered__cr" = "CR",
  "endangered__en" = "EN", "vulnerable__vu" = "VU",
  "near_threatened__nt" = "NT", "least_concern__lc" = "LC", "data_deficient__dd" = "DD"
)

iucn_colors <- c(
  "regionally_extinct__re" = "black", "critically_endangered__cr" = "#B22222",
  "endangered__en" = "#FF4500", "vulnerable__vu" = "#FFA500",
  "near_threatened__nt" = "#FFFF99", "least_concern__lc" = "#9ACD32", "data_deficient__dd" = "#A9A9A9"
)

plot_data <- combined_Ne500_indicators %>%
  filter(!is.na(indicator_0.1)) %>%
  mutate(
    indicator_0.1 = pmin(pmax(indicator_0.1, 0), 1),
    Current_National_Red_List_Category = factor(
      Current_National_Red_List_Category, levels = iucn_levels
    )
  )

label_counts <- tibble(Current_National_Red_List_Category = iucn_levels) %>%
  left_join(plot_data %>% count(Current_National_Red_List_Category), by = "Current_National_Red_List_Category") %>%
  mutate(
    n     = replace_na(n, 0),
    label = paste0(iucn_labels[Current_National_Red_List_Category], " (n=", n, ")")
  )

ne_threat_plot <- ggplot(plot_data, aes(
    y = Current_National_Red_List_Category,
    x = indicator_0.1,
    fill = Current_National_Red_List_Category
  )) +
  geom_violin(
    data = plot_data %>% group_by(Current_National_Red_List_Category) %>% filter(n() > 1),
    scale = "width", trim = TRUE, color = NA, alpha = 0.8
  ) +
  geom_jitter(width = 0.05, size = 1.8, alpha = 0.6, color = "black") +
  scale_y_discrete(
    limits = rev(iucn_levels),
    labels = setNames(label_counts$label, iucn_levels)
  ) +
  scale_fill_manual(values = iucn_colors) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = "Distribution of Ne500 Indicator by Regional IUCN Threat Status",
    x = "Proportion of populations within species with Ne > 500",
    y = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "none", axis.text.y = element_text(size = 11),
        axis.text.x = element_text(size = 10), plot.title = element_text(size = 13))

ne_threat_plot
ggsave("Ne500_indicator_plot.png", plot = ne_threat_plot, width = 7, height = 5, units = "in", dpi = 300)

# Faceted plot for all three ratios
plot_data_long <- combined_Ne500_indicators %>%
  select(taxon, Current_National_Red_List_Category, indicator_0.1, indicator_0.2, indicator_0.3) %>%
  pivot_longer(cols = starts_with("indicator_"), names_to = "Ne_ratio", values_to = "Ne_value") %>%
  filter(!is.na(Ne_value)) %>%
  mutate(
    Ne_value = pmin(pmax(Ne_value, 0), 1),
    Current_National_Red_List_Category = factor(
      Current_National_Red_List_Category, levels = iucn_levels
    ),
    Ne_ratio = factor(Ne_ratio,
      levels = c("indicator_0.1", "indicator_0.2", "indicator_0.3"),
      labels = c("0.1", "0.2", "0.3")
    )
  )

label_counts_long <- plot_data_long %>%
  group_by(Current_National_Red_List_Category) %>%
  summarize(n = n_distinct(taxon), .groups = "drop") %>%
  mutate(label = paste0(iucn_labels[Current_National_Red_List_Category], " (n=", n, ")"))

ne_threat_plot_long <- ggplot(plot_data_long, aes(
    y = Current_National_Red_List_Category,
    x = Ne_value,
    fill = Current_National_Red_List_Category
  )) +
  geom_violin(
    data = plot_data_long %>% group_by(Current_National_Red_List_Category, Ne_ratio) %>% filter(n() > 1),
    scale = "width", trim = TRUE, color = NA, alpha = 0.8
  ) +
  geom_jitter(width = 0.05, size = 1.8, alpha = 0.6, color = "black") +
  scale_y_discrete(
    limits = rev(iucn_levels),
    labels = setNames(label_counts_long$label, label_counts_long$Current_National_Red_List_Category)
  ) +
  scale_fill_manual(values = iucn_colors) +
  scale_x_continuous(limits = c(-0.07, 1.07), expand = expansion(mult = c(0, 0))) +
  facet_wrap(~ Ne_ratio, ncol = 3, scales = "free_x",
             labeller = as_labeller(c("0.1" = "a) Ne/Nc = 0.1", "0.2" = "b) Ne/Nc = 0.2", "0.3" = "c) Ne/Nc = 0.3"))) +
  labs(x = "Proportion of populations within species with Ne > 500", y = NULL) +
  theme_minimal() +
  theme(legend.position = "none", axis.text.y = element_text(size = 11),
        axis.text.x = element_text(size = 10))

ne_threat_plot_long
ggsave("Ne500_indicator_plot_0.1-0.3.png", plot = ne_threat_plot_long, width = 7, height = 5, units = "in", dpi = 300)

# Population-level Ne by threat status (clipped at Ne = 1500)
set.seed(123)

iucn_levels_no_re <- c(
  "critically_endangered__cr", "endangered__en", "vulnerable__vu",
  "near_threatened__nt", "least_concern__lc", "data_deficient__dd"
)

plot_data_ne <- Ne500_long %>%
  filter(!is.na(Ne_value)) %>%
  mutate(
    Current_National_Red_List_Category = factor(
      Current_National_Red_List_Category, levels = rev(iucn_levels_no_re)
    )
  )

label_counts_ne <- tibble(Current_National_Red_List_Category = rev(iucn_levels_no_re)) %>%
  left_join(plot_data_ne %>% count(Current_National_Red_List_Category), by = "Current_National_Red_List_Category") %>%
  mutate(
    n     = replace_na(n, 0),
    label = paste0(iucn_labels[Current_National_Red_List_Category], " (n=", n, ")")
  )

ggplot(plot_data_ne, aes(
    y = Current_National_Red_List_Category,
    x = Ne_value,
    fill = Current_National_Red_List_Category
  )) +
  geom_violin(
    data = plot_data_ne %>% group_by(Current_National_Red_List_Category) %>% filter(n() > 1),
    aes(x = Ne_value, y = Current_National_Red_List_Category),
    scale = "width", trim = FALSE, color = NA, alpha = 0.8
  ) +
  geom_jitter(width = 0.05, size = 1.8, alpha = 0.6, color = "black") +
  scale_y_discrete(labels = setNames(label_counts_ne$label, label_counts_ne$Current_National_Red_List_Category)) +
  scale_fill_manual(values = iucn_colors) +
  scale_x_continuous(limits = c(0, 1500), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Distribution of Population-level Ne by Regional IUCN Threat Status",
    x = "Ne", y = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "none", axis.text.y = element_text(size = 11),
        axis.text.x = element_text(size = 10), plot.title = element_text(size = 13))

# ----------------------------------------------------------
# 5.5.5 Ne500 by species range
# ----------------------------------------------------------

Ne500_byRange <- combined_Ne500_indicators %>%
  group_by(species_range) %>%
  summarise(
    n_taxa            = n(),
    avg_indicator_0.1 = mean(indicator_0.1, na.rm = TRUE),
    sd_indicator_0.1  = sd(indicator_0.1, na.rm = TRUE),
    avg_indicator_0.2 = mean(indicator_0.2, na.rm = TRUE),
    sd_indicator_0.2  = sd(indicator_0.2, na.rm = TRUE),
    avg_indicator_0.3 = mean(indicator_0.3, na.rm = TRUE),
    sd_indicator_0.3  = sd(indicator_0.3, na.rm = TRUE),
    .groups = "drop"
  )

Ne500_byRange
