# ============================================================
# 04_PM_indicator.R
# Calculate the Populations Maintained (PM) indicator and
# explore differences across taxonomic and ecological groups.
# Requires: kobo.cleaned from 02_quality_checks.R
# ============================================================

library(dplyr)
library(ggplot2)
library(knitr)
library(rstatix)
library(tibble)

# ----------------------------------------------------------
# 4.1 Extract PM dataset (remove rows with NA pop counts)
# ----------------------------------------------------------

PM_data <- kobo.cleaned %>%
  filter(!(is.na(n_extinct_populations) | is.na(n_extant_populations)))

PM_data %>%
  select(taxon, n_extant_populations, n_extinct_populations)

# ----------------------------------------------------------
# 4.2 Calculate PM indicator per taxon
# ----------------------------------------------------------

PM_data$indicator_PM <- PM_data$n_extant_populations /
  (PM_data$n_extant_populations + PM_data$n_extinct_populations)

# ----------------------------------------------------------
# 4.3 National PM indicator — average by taxonomic group
# ----------------------------------------------------------

avg_PM_by_taxonomic_group <- PM_data %>%
  group_by(taxonomic_group) %>%
  summarise(
    avg_indicator_PM = mean(indicator_PM, na.rm = TRUE),
    sd_indicator_PM  = sd(indicator_PM, na.rm = TRUE),
    n                = sum(!is.na(indicator_PM)),
    se_indicator_PM  = sd_indicator_PM / sqrt(n),
    .groups = "drop"
  )

avg_PM_by_taxonomic_group
knitr::kable(avg_PM_by_taxonomic_group, caption = "Average PM by Taxonomic Group")

PM_data %>%
  filter(taxon == "Lycaon pictus") %>%
  select(taxon, n_extant_populations, n_extinct_populations)

# PM threshold summary
PM_threshold_summary <- PM_data %>%
  group_by(taxonomic_group) %>%
  summarise(
    n_total       = sum(!is.na(indicator_PM)),
    n_PM_lt_0.75  = sum(indicator_PM < 0.75, na.rm = TRUE),
    n_PM_lt_0.25  = sum(indicator_PM < 0.25, na.rm = TRUE),
    prop_PM_lt_0.75 = n_PM_lt_0.75 / n_total,
    prop_PM_lt_0.25 = n_PM_lt_0.25 / n_total,
    .groups = "drop"
  )

PM_threshold_summary

pm_rank_plot <- PM_data %>%
  filter(!is.na(indicator_PM)) %>%
  arrange(indicator_PM) %>%
  mutate(rank = row_number()) %>%
  ggplot(aes(x = rank, y = indicator_PM)) +
  geom_point(alpha = 0.7) +
  geom_hline(yintercept = c(0.75, 0.25), linetype = "dashed") +
  labs(x = "Taxa (ranked)", y = "Populations Maintained indicator value") +
  theme_minimal()

pm_rank_plot

ggsave("PM_indicator_ranked_taxa.png", plot = pm_rank_plot, width = 18, height = 12, units = "cm", dpi = 300)

# Use code below only when more than one taxonomic group is in the dataset
# SA_avg_PM <- mean(sapply(avg_PM_by_taxonomic_group, function(df) df$avg_indicator_PM), na.rm = TRUE)
# SA_avg_PM

# ----------------------------------------------------------
# 4.4.1 PM by Taxonomic Order
# ----------------------------------------------------------

avg_PM_by_Order <- PM_data %>%
  group_by(Taxonomic_Order) %>%
  summarise(
    avg_indicator_PM = mean(indicator_PM, na.rm = TRUE),
    sd_indicator_PM  = sd(indicator_PM, na.rm = TRUE),
    n                = sum(!is.na(indicator_PM)),
    se_indicator_PM  = sd_indicator_PM / sqrt(n),
    .groups = "drop"
  )

avg_PM_by_Order
kruskal.test(indicator_PM ~ Taxonomic_Order, data = PM_data)
knitr::kable(avg_PM_by_Order, caption = "Average PM by Taxonomic Order")
write.csv(avg_PM_by_Order, "avg_PM_by_Mammal_Order.csv", row.names = FALSE)

# ----------------------------------------------------------
# 4.4.2 PM by Endemism
# ----------------------------------------------------------

avg_PM_by_endemism <- PM_data %>%
  group_by(endemic_status) %>%
  summarise(
    avg_indicator_PM = mean(indicator_PM, na.rm = TRUE),
    sd_indicator_PM  = sd(indicator_PM, na.rm = TRUE),
    n                = sum(!is.na(indicator_PM)),
    se_indicator_PM  = sd_indicator_PM / sqrt(n),
    .groups = "drop"
  )

avg_PM_by_endemism

wilcox.test(indicator_PM ~ endemic_status, data = PM_data, exact = FALSE)

# ----------------------------------------------------------
# 4.4.3 PM by Threat Status
# ----------------------------------------------------------

avg_PM_by_threat_status <- PM_data %>%
  group_by(Current_National_Red_List_Category) %>%
  summarise(
    avg_indicator_PM = mean(indicator_PM, na.rm = TRUE),
    sd_indicator_PM  = sd(indicator_PM, na.rm = TRUE),
    n                = n(),
    se_indicator_PM  = sd_indicator_PM / sqrt(n),
    .groups = "drop"
  )

avg_PM_by_threat_status
kruskal.test(indicator_PM ~ Current_National_Red_List_Category, data = PM_data)
PM_data %>% kruskal_effsize(indicator_PM ~ Current_National_Red_List_Category)

dunn_results <- PM_data %>%
  dunn_test(indicator_PM ~ Current_National_Red_List_Category, p.adjust.method = "holm")

write.csv(dunn_results, "Dunn_posthoc_PM_by_threat_status.csv")
dunn_results

set.seed(123)

iucn_levels <- c(
  "least_concern__lc", "near_threatened__nt", "vulnerable__vu",
  "endangered__en", "critically_endangered__cr", "data_deficient__dd", "regionally_extinct__re"
)

iucn_colors <- c(
  "least_concern__lc" = "#9ACD32", "near_threatened__nt" = "#FFFF99",
  "vulnerable__vu" = "#FFA500", "endangered__en" = "#FF4500",
  "critically_endangered__cr" = "#B22222", "data_deficient__dd" = "#A9A9A9",
  "regionally_extinct__re" = "#000000"
)

iucn_labels <- c(
  "least_concern__lc" = "LC", "near_threatened__nt" = "NT", "vulnerable__vu" = "VU",
  "endangered__en" = "EN", "critically_endangered__cr" = "CR",
  "data_deficient__dd" = "DD", "regionally_extinct__re" = "RE"
)

plot_data <- PM_data %>%
  mutate(Current_National_Red_List_Category = factor(
    Current_National_Red_List_Category, levels = iucn_levels
  ))

label_counts <- tibble(Current_National_Red_List_Category = iucn_levels) %>%
  left_join(plot_data %>% count(Current_National_Red_List_Category), by = "Current_National_Red_List_Category") %>%
  mutate(
    n = replace_na(n, 0),
    label = paste0(iucn_labels[Current_National_Red_List_Category], " (n=", n, ")")
  )

y_labels_with_n <- setNames(label_counts$label, label_counts$Current_National_Red_List_Category)

p_pm <- ggplot(plot_data, aes(y = Current_National_Red_List_Category, x = indicator_PM)) +
  geom_jitter(height = 0.15, width = 0, size = 1.8, alpha = 0.6) +
  stat_summary(fun = median, geom = "point", size = 4, shape = 95) +
  scale_y_discrete(labels = y_labels_with_n) +
  scale_x_continuous(limits = c(0, 1)) +
  labs(x = "Populations Maintained indicator value", y = "Regional IUCN Red List categories") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 11), axis.text.x = element_text(size = 10))

p_pm

ggsave("PM_indicator_by_RedList_category.png", plot = p_pm, width = 7, height = 4.5, dpi = 300)
ggsave("PM_indicator_by_RedList_category.pdf", plot = p_pm, width = 7, height = 4.5)

# ----------------------------------------------------------
# 4.4.4 PM by Realm
# ----------------------------------------------------------

avg_PM_by_realm <- PM_data %>%
  group_by(realm) %>%
  summarise(
    avg_indicator_PM = mean(indicator_PM, na.rm = TRUE),
    sd_indicator_PM  = sd(indicator_PM, na.rm = TRUE),
    n                = sum(!is.na(indicator_PM)),
    se_indicator_PM  = sd_indicator_PM / sqrt(n),
    .groups = "drop"
  )

avg_PM_by_realm
kruskal.test(indicator_PM ~ realm, data = PM_data)
PM_data %>% kruskal_effsize(indicator_PM ~ realm)

dunn_realm <- PM_data %>%
  dunn_test(indicator_PM ~ realm, p.adjust.method = "BH")

dunn_realm
knitr::kable(avg_PM_by_realm, caption = "Average PM by Realm")

unique(PM_data$realm)

realm_query <- PM_data %>%
  filter(realm %in% c("marine terrestrial", "freshwater terrestrial")) %>%
  select(Taxonomic_Order, taxon, common_name, realm, name_assessor)

realm_query
write.csv(realm_query, "Realm_queries.csv", row.names = FALSE)

# ----------------------------------------------------------
# 4.4.5 Historical vs current population change
# ----------------------------------------------------------

PM_data <- PM_data %>%
  mutate(
    pop_change_direction = case_when(
      !is.na(n_hist_pops) & !is.na(n_extant_populations) & n_extant_populations > n_hist_pops ~ "increase",
      !is.na(n_hist_pops) & !is.na(n_extant_populations) & n_extant_populations < n_hist_pops ~ "decrease",
      !is.na(n_hist_pops) & !is.na(n_extant_populations) & n_extant_populations == n_hist_pops ~ "no_change",
      TRUE ~ NA_character_
    )
  )

coverage_summary <- PM_data %>%
  summarise(
    total_taxa             = n(),
    taxa_with_diff_data    = sum(!is.na(pop_change_direction)),
    taxa_without_diff_data = total_taxa - taxa_with_diff_data,
    prop_with_data         = taxa_with_diff_data / total_taxa
  )

coverage_summary

pop_change_counts <- PM_data %>%
  filter(!is.na(pop_change_direction)) %>%
  count(pop_change_direction) %>%
  mutate(percent = n / sum(n) * 100)

pop_change_counts

pop_change_taxa_list <- PM_data %>%
  filter(!is.na(pop_change_direction)) %>%
  select(taxon, pop_change_direction, Current_National_Red_List_Category) %>%
  arrange(pop_change_direction, Current_National_Red_List_Category)

pop_change_taxa_list
