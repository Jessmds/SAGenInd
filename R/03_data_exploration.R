# ============================================================
# 03_data_exploration.R
# Explore the cleaned dataset: taxa, population definitions,
# and population size data availability.
# Requires: kobo.cleaned from 02_quality_checks.R
# ============================================================

library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(knitr)

# ----------------------------------------------------------
# 3.1.1 Taxon assessment level
# ----------------------------------------------------------

kobo.cleaned %>%
  mutate(level = ifelse(!is.na(subspecies_variety) & subspecies_variety != "", "subspecies", "species")) %>%
  count(level, name = "n") %>%
  kable()

kobo.cleaned %>%
  filter(!is.na(subspecies_variety)) %>%
  select(taxon, common_name)

taxon_na_summary <- kobo.cleaned %>%
  mutate(
    has_missing = if_else(
      is.na(n_extinct_populations) | is.na(n_extant_populations),
      "Missing data", "Complete data"
    )
  ) %>%
  distinct(taxon, has_missing) %>%
  count(has_missing) %>%
  mutate(proportion = n / sum(n))

taxon_na_summary

complete_taxa <- kobo.cleaned %>%
  mutate(
    has_missing = if_else(
      is.na(n_extinct_populations) | is.na(n_extant_populations),
      "Missing data", "Complete data"
    )
  ) %>%
  filter(has_missing == "Complete data") %>%
  distinct(taxon) %>%
  arrange(taxon)

complete_taxa

ggplot(taxon_na_summary, aes(x = "", y = n, fill = has_missing)) +
  geom_col(width = 1) +
  coord_polar(theta = "y") +
  labs(title = "Proportion of Taxa with Population Data") +
  theme_void() +
  scale_fill_manual(values = c("Complete data" = "#4CAF50", "Missing data" = "#F44336"))

# ----------------------------------------------------------
# 3.1.2 How populations are defined
# ----------------------------------------------------------

kobo.cleaned %>%
  count(defined_populations, name = "n") %>%
  mutate(defined_populations = substr(defined_populations, 1, 50)) %>%
  select(defined_populations, n) %>%
  arrange(desc(n)) %>%
  kable()

defined_pops_summary <- kobo.cleaned %>%
  count(defined_populations, name = "n") %>%
  mutate(defined_populations = substr(defined_populations, 1, 50))

top_defined <- defined_pops_summary %>%
  filter(n >= 15)

other_combination <- defined_pops_summary %>%
  filter(n < 15) %>%
  summarise(defined_populations = "other_combinations", n = sum(n))

popdef_summary <- bind_rows(top_defined, other_combination) %>%
  arrange(desc(n))

popdef_summary %>% kable()

# ----------------------------------------------------------
# 3.1.3.1 Population size data availability
# ----------------------------------------------------------

colnames(kobo.cleaned)

summary(as.factor(kobo.cleaned$popsize_data))

kobo.cleaned$popsize_data <- factor(
  kobo.cleaned$popsize_data,
  levels = c("insuff_data_species", "data_for_species", "yes")
)

ggplot(kobo.cleaned, aes(x = popsize_data, fill = popsize_data)) +
  geom_bar(color = "white") +
  scale_fill_manual(
    values = c("grey80", "#1f77b4", "#2ca02c"),
    labels = c("Insufficient data", "Species-level data", "Population-level data")
  ) +
  labs(x = "Population size data availability", y = "Number of taxa", fill = "") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))

popsize_counts <- kobo.cleaned %>%
  count(popsize_data) %>%
  mutate(
    percent = round(n / sum(n) * 100, 1),
    label = paste0(percent, "%")
  )

popsize_counts$popsize_data <- factor(
  popsize_counts$popsize_data,
  levels = c("insuff_data_species", "data_for_species", "yes")
)

data_avail <- ggplot(popsize_counts, aes(x = 2, y = n, fill = popsize_data)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  xlim(0.5, 2.5) +
  geom_text(aes(label = label), position = position_stack(vjust = 0.5), color = "white", size = 5) +
  scale_fill_manual(
    values = c("grey80", "#1f77b4", "#2ca02c"),
    labels = c("Insufficient data", "Species-level data", "Population-level data")
  ) +
  labs(fill = "Population size data availability", title = NULL) +
  theme_void() +
  theme(legend.position = "right")

ggsave("Donut_Available_Pop_Data.png", plot = data_avail, width = 7, height = 4.5, dpi = 300)
ggsave("Donut_Available_Pop_Data.pdf", plot = data_avail, width = 7, height = 4.5)

# ----------------------------------------------------------
# 3.1.3.2 Breakdown by Taxonomic Order, Threat Status, Realm
# ----------------------------------------------------------

ggplot(kobo.cleaned, aes(x = popsize_data, fill = popsize_data)) +
  geom_bar(color = "white") +
  scale_fill_manual(
    values = c("grey80", "#1f77b4", "#2ca02c"),
    labels = c("Insufficient data", "Species-level data", "Population-level data")
  ) +
  labs(x = "Population size data availability", y = "Number of taxa", fill = "") +
  facet_wrap(~ Taxonomic_Order, scales = "free_y") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("Pop_Data_By_Order.pdf", width = 31, height = 25, units = "cm")

ggplot(kobo.cleaned, aes(x = popsize_data, fill = popsize_data)) +
  geom_bar(color = "white") +
  scale_fill_manual(
    values = c("grey80", "#1f77b4", "#2ca02c"),
    labels = c("Insufficient data", "Species-level data", "Population-level data")
  ) +
  labs(x = "Population size data availability", y = "Number of taxa", fill = "") +
  facet_wrap(~ Current_National_Red_List_Category) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", axis.text.x = element_text(angle = 45, hjust = 1))

kobo.cleaned$popsize_data <- factor(
  kobo.cleaned$popsize_data,
  levels = c("insuff_data_species", "data_for_species", "yes")
)

popsize_plot <- ggplot(kobo.cleaned, aes(x = Taxonomic_Order, fill = popsize_data)) +
  geom_bar(stat = "count", color = "white") +
  coord_flip() +
  facet_wrap(~ Current_National_Red_List_Category, ncol = 3, scales = "free_y") +
  scale_fill_manual(
    values = c("#999999", "#1f77b4", "#2ca02c"),
    breaks = c("yes", "data_for_species", "insuff_data_species"),
    labels = c("Population level", "Species/subspecies level", "Insufficient data")
  ) +
  labs(fill = "Population size data availability", x = "Taxonomic Order", y = "Number of taxa") +
  theme_light() +
  theme(
    panel.border = element_blank(), legend.position = "top",
    axis.text.y = element_text(size = 8), strip.text = element_text(size = 10, face = "bold")
  )

print(popsize_plot)
ggsave("popsize_by_order_and_threat.pdf", popsize_plot, width = 12, height = 8, units = "in")

ggplot(kobo.cleaned, aes(x = popsize_data, fill = popsize_data)) +
  geom_bar(color = "white") +
  scale_fill_manual(
    values = c("grey80", "#1f77b4", "#2ca02c"),
    labels = c("Insufficient data", "Species-level data", "Population-level data")
  ) +
  labs(x = "Population size data availability", y = "Number of taxa", fill = "") +
  facet_wrap(~ realm) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", axis.text.x = element_text(angle = 45, hjust = 1))

# ----------------------------------------------------------
# 3.1.3.3 Ne vs Nc data overview
# ----------------------------------------------------------

unique(kobo.cleaned$popsize_data)

kobo.cleaned %>%
  filter(tolower(popsize_data) == "yes") %>%
  nrow()

kobo.cleaned %>%
  filter(tolower(popsize_data) == "yes") %>%
  select(ne_pops_exists, nc_pops_exists) %>%
  distinct()

ps_data <- kobo.cleaned %>%
  filter(tolower(popsize_data) == "yes") %>%
  mutate(
    ne_clean = tolower(trimws(ne_pops_exists)),
    nc_clean = tolower(trimws(nc_pops_exists))
  )

kobo_flagged <- ps_data %>%
  mutate(
    has_ne = ne_clean == "ne_available",
    has_nc = nc_clean == "yes"
  )

ps_summary <- kobo_flagged %>%
  group_by(taxon) %>%
  summarise(
    any_ne = any(has_ne, na.rm = TRUE),
    any_nc = any(has_nc, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    data_combination = case_when(
      any_ne & any_nc  ~ "ne + nc",
      any_ne & !any_nc ~ "ne only",
      !any_ne & any_nc ~ "nc only",
      TRUE             ~ "no ne/nc data"
    )
  )

ps_summary %>% count(data_combination)

# Nc data type breakdown
nc_data <- kobo.cleaned %>%
  filter(tolower(nc_pops_exists) == "yes")

nc_type_cols <- paste0("NcType_pop", 1:25)

kobo.cleaned %>%
  filter(tolower(nc_pops_exists) == "yes") %>%
  select(taxon, starts_with("NcType_Pop")) %>%
  head()

nc_tally <- kobo.cleaned %>%
  filter(tolower(nc_pops_exists) == "yes") %>%
  select(all_of(nc_type_cols)) %>%
  pivot_longer(cols = everything(), names_to = "population", values_to = "NcType") %>%
  filter(!is.na(NcType) & NcType != "") %>%
  count(NcType, sort = TRUE)

nc_tally

nc_types_list <- kobo.cleaned %>%
  filter(tolower(nc_pops_exists) == "yes") %>%
  select(taxon, all_of(nc_type_cols)) %>%
  pivot_longer(cols = all_of(nc_type_cols), names_to = "population", values_to = "NcType") %>%
  filter(!is.na(NcType) & NcType != "") %>%
  mutate(pop = as.integer(gsub("NcType_pop", "", population))) %>%
  select(taxon, pop, NcType)

nc_types_list %>%
  distinct(taxon, NcType) %>%
  count(NcType, name = "unique_taxa_count") %>%
  arrange(desc(unique_taxa_count))

taxa_nc_duplicates <- nc_types_list %>%
  distinct(taxon, NcType) %>%
  add_count(taxon) %>%
  filter(n > 1) %>%
  arrange(taxon)

taxa_nc_duplicates

taxa_nc <- nc_types_list %>%
  distinct(taxon, NcType)

taxa_with_both <- taxa_nc %>%
  filter(NcType %in% c("Nc_range", "Nc_point")) %>%
  group_by(taxon) %>%
  summarise(n_types = n_distinct(NcType), .groups = "drop") %>%
  filter(n_types == 2)

taxa_nc %>% filter(taxon %in% taxa_with_both$taxon)

taxa_census <- kobo.cleaned %>%
  filter(tolower(nc_pops_exists) == "yes") %>%
  select(taxon, all_of(nc_type_cols)) %>%
  pivot_longer(cols = starts_with("NcType_Pop"), values_to = "NcType") %>%
  filter(!is.na(NcType) & NcType != "") %>%
  distinct(taxon, NcType) %>%
  count(NcType, sort = TRUE)

taxa_census

# Cross-check Nc taxa uniqueness
nc_range_taxa <- taxa_nc %>% filter(NcType == "Nc_range") %>% select(taxon)
nc_point_taxa <- taxa_nc %>% filter(NcType == "Nc_point") %>% select(taxon)
unknown_taxa  <- taxa_nc %>% filter(NcType == "unknown")  %>% select(taxon)

inner_join(nc_range_taxa, nc_point_taxa, by = "taxon")
anti_join(nc_range_taxa, nc_point_taxa, by = "taxon")

known_taxa <- bind_rows(nc_range_taxa, nc_point_taxa) %>% distinct()
unique_unknown <- anti_join(unknown_taxa, known_taxa, by = "taxon")
unique_unknown

# Nc visualisations
unique(nc_tally$NcType)

ggplot(nc_tally, aes(x = NcType, y = n, fill = NcType)) +
  geom_bar(stat = "identity", width = 0.7) +
  labs(title = "Type of Census Data by Population", x = "Nc Type", y = "Number of Populations") +
  scale_fill_manual(values = c("Nc_range" = "#1f77b4", "Nc_point" = "#2ca02c")) +
  theme_minimal() +
  theme(legend.position = "none")

ggplot(taxa_census, aes(x = reorder(NcType, n), y = n, fill = NcType)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Number of Taxa with Each Type of Nc Data", x = "Nc Type", y = "Number of Taxa") +
  scale_fill_manual(values = c("Nc_range" = "#1f77b4", "Nc_point" = "#2ca02c")) +
  theme_minimal() +
  theme(legend.position = "none")

# Ne data overview
kobo.cleaned$ne_pops_exists

ne_cols <- paste0("Ne_pop", 1:25)

kobo.cleaned %>%
  filter(tolower(ne_pops_exists) == "ne_available") %>%
  select(taxon, starts_with("Ne_pop"))

ne_counts <- kobo.cleaned %>%
  filter(tolower(ne_pops_exists) == "ne_available") %>%
  select(taxon, all_of(ne_cols)) %>%
  pivot_longer(cols = all_of(ne_cols), names_to = "population", values_to = "Ne_value") %>%
  filter(!is.na(Ne_value) & Ne_value != "") %>%
  summarise(n_Ne_pops = n())

ne_counts

Ne_pops <- kobo.cleaned %>%
  filter(tolower(ne_pops_exists) == "ne_available") %>%
  select(taxon, all_of(ne_cols)) %>%
  pivot_longer(cols = all_of(ne_cols), names_to = "pop", values_to = "Ne")

Ne_pops %>%
  filter(!is.na(Ne)) %>%
  select(taxon, pop, Ne) %>%
  arrange(taxon, pop)

taxa_ne <- Ne_pops %>%
  filter(!is.na(Ne)) %>%
  distinct(taxon)

taxa_ne

anti_join(taxa_nc, taxa_ne, by = "taxon")
anti_join(taxa_ne, taxa_nc, by = "taxon")
inner_join(taxa_nc, taxa_ne, by = "taxon")

bind_rows(
  mutate(taxa_nc, source = "Nc"),
  mutate(taxa_ne, source = "Ne")
) %>%
  group_by(taxon) %>%
  summarise(source = paste(sort(unique(source)), collapse = ", ")) %>%
  arrange(taxon)

# Combined Ne + Nc visualisation
nc_total <- nc_tally %>%
  rename(category = NcType) %>%
  mutate(type = "Nc")

ne_total <- ne_counts %>%
  summarise(n = sum(n_Ne_pops, na.rm = TRUE)) %>%
  mutate(category = "Ne", type = "Ne")

combined_data <- bind_rows(nc_total, ne_total) %>%
  select(type, category, n) %>%
  arrange(type, desc(n))

combined_data

ggplot(combined_data, aes(x = category, y = n, fill = category)) +
  geom_col(width = 0.7, color = "white") +
  scale_fill_manual(values = c("Ne" = "darkgreen", "Nc_point" = "#3388CC", "Nc_range" = "#E69F00", "unknown" = "grey80")) +
  labs(title = "Number of Populations by Population Data Category", x = "Population Size Data", y = "Number of Populations") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

donut_data <- combined_data %>%
  mutate(
    fraction = n / sum(n),
    ymax = cumsum(fraction),
    ymin = lag(ymax, default = 0),
    label = paste0(category, "\n(", n, ")")
  )

ggplot(donut_data) +
  geom_rect(aes(ymin = ymin, ymax = ymax, xmin = 3, xmax = 4, fill = category), color = "white") +
  coord_polar(theta = "y") +
  xlim(c(2, 4)) +
  scale_fill_manual(values = c("Ne" = "darkgreen", "Nc_point" = "#3388CC", "Nc_range" = "#E69F00", "unknown" = "grey80")) +
  theme_void() +
  labs(title = "Number of Populations by Population Size Data Category") +
  theme(legend.title = element_blank())
