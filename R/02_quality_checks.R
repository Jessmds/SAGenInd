# ============================================================
# 02_quality_checks.R
# Quality checks on the imported/filtered Kobo dataset.
# Requires: kobo.2 from 01_data_import.R
# ============================================================

library(dplyr)
library(stringr)
library(ggplot2)
library(knitr)
library(tibble)
library(tidyr)

kobo.3 <- kobo.2 %>%
  mutate(
    n_extant_populations  = na_if(as.integer(n_extant_populations), -999),
    n_extinct_populations = na_if(as.integer(n_extinct_populations), -999),
    n_hist_pops           = na_if(as.integer(n_hist_pops), -999)
  ) %>%
  mutate(across(where(is.character), ~ str_trim(.))) %>%
  mutate(across(where(is.character), ~ na_if(., "")))

kobo.3$n_extant_populations
kobo.2$n_extant_populations
kobo.3$n_extinct_populations
kobo.2$n_extinct_populations

check_n_pops <- kobo.3 %>%
  filter(
    n_extant_populations < 0 |
    n_extant_populations == 0 |
    n_hist_pops == 0 |
    n_extant_populations == 999 |
    n_extinct_populations == 999 |
    n_hist_pops == 999
  ) %>%
  mutate(issue = "Check population numbers (e.g. 0 or 999 may be incorrect)") %>%
  select(name_assessor, taxon, n_extant_populations, n_extinct_populations, n_hist_pops, issue)

check_n_pops

required_fields <- c(
  "taxon", "Taxonomic_Order", "n_extant_populations", "n_extinct_populations", "realm",
  "national_endemic", "Previous_National_Red_List_Category",
  "Current_National_Red_List_Category", "IUCN_habitat", "species_range"
)

missing_info <- kobo.3 %>%
  filter(if_any(all_of(required_fields), ~ is.na(.))) %>%
  mutate(issue = "Missing value in population information") %>%
  select(name_assessor, taxon, all_of(required_fields), issue)

missing_info

check_taxon_names <- kobo.3 %>%
  filter(
    grepl(" ", genus) |
    grepl(" ", species) |
    grepl(" ", subspecies_variety)
  ) %>%
  filter(!grepl("var.", subspecies_variety)) %>%
  filter(!grepl("subsp.", subspecies_variety)) %>%
  mutate(issue = "Check name format. More than 2 words") %>%
  select(name_assessor, genus, species, subspecies_variety, taxon, issue)

check_taxon_names

dp_other_comments <- kobo.3 %>%
  filter(defined_populations == "other" & !is.na(source_definition_populations) & source_definition_populations != "") %>%
  mutate(issue = "Other population def. Review explanation") %>%
  select(name_assessor, taxon, defined_populations, source_definition_populations, issue)

dp_other_comments

summary(kobo.3$n_extant_populations)
ggplot(kobo.3, aes(x = n_extant_populations)) + geom_histogram()

taxa_over5 <- kobo.3 %>%
  filter(n_extant_populations > 5) %>%
  select(taxon, n_extant_populations)
taxa_over5

kobo.3 %>%
  filter(n_extant_populations >= 0, n_extant_populations < 25) %>%
  ggplot(., aes(x = n_extant_populations)) + geom_histogram()

summary(kobo.2$n_extinct_populations)
ggplot(kobo.3, aes(x = n_extinct_populations)) + geom_histogram()

pop_summary <- tibble::tibble(
  Type = c("Total", "Mean", "Total", "Mean"),
  Population = c("Extant", "Extant", "Extinct", "Extinct"),
  Value = c(
    sum(kobo.3$n_extant_populations, na.rm = TRUE),
    mean(kobo.3$n_extant_populations, na.rm = TRUE),
    sum(kobo.3$n_extinct_populations, na.rm = TRUE),
    mean(kobo.3$n_extinct_populations, na.rm = TRUE)
  )
)

kobo_long <- kobo.3 %>%
  select(n_extant_populations, n_extinct_populations) %>%
  pivot_longer(everything(), names_to = "Population_Type", values_to = "Count")

ggplot(kobo_long, aes(x = Population_Type, y = Count)) +
  geom_boxplot(fill = "skyblue") +
  labs(title = "Distribution of Population Counts", y = "Count", x = "Type") +
  theme_minimal()

pop_summary %>%
  pivot_wider(names_from = Type, values_from = Value) %>%
  kable(caption = "Summary Statistics for Extant and Extinct Populations")

extant_NA <- kobo.3 %>%
  filter(is.na(n_extant_populations)) %>%
  mutate(issue = "Why is extant pops NA?") %>%
  select(name_assessor, taxon, n_extant_populations, issue)
extant_NA

extinct_NA <- kobo.3 %>%
  filter(is.na(n_extinct_populations)) %>%
  mutate(issue = "Why is extinct pops NA?") %>%
  select(name_assessor, taxon, n_extinct_populations, issue)
extinct_NA

kobo.3 %>%
  filter(n_extant_populations == 0) %>%
  select(taxon, name_assessor, n_extant_populations, n_extinct_populations)

extinct_pop <- kobo.3 %>%
  filter(n_extinct_populations > 0) %>%
  mutate(issue = "Extinct populations present. Confirm if valid") %>%
  select(name_assessor, taxon, common_name, n_extinct_populations, issue)
extinct_pop

unique(kobo.3$diff_historical_pop)

kobo.3 %>%
  filter(diff_historical_pop == "yes") %>%
  select(name_assessor, taxon, genus, species, subspecies_variety, Taxonomic_Order,
         n_extant_populations, n_extinct_populations, n_hist_pops, realm,
         national_endemic, Previous_National_Red_List_Category,
         Current_National_Red_List_Category, IUCN_habitat, species_range)

table(tolower(kobo.3$diff_historical_pop))

kobo.3 %>%
  filter(diff_historical_pop == "yes" & n_hist_pops < n_extant_populations) %>%
  select(name_assessor, taxon, Taxonomic_Order, n_extant_populations,
         n_extinct_populations, n_hist_pops, realm, national_endemic,
         Previous_National_Red_List_Category, Current_National_Red_List_Category,
         IUCN_habitat, species_range)

unique(kobo.3$popsize_data)

kobo.3 %>%
  filter(tolower(popsize_data) == "yes") %>%
  nrow()

kobo.3 %>%
  filter(tolower(popsize_data) == "yes") %>%
  select(ne_pops_exists, nc_pops_exists) %>%
  distinct()

psize_data <- kobo.3 %>%
  filter(tolower(popsize_data) == "yes") %>%
  mutate(
    ne_clean = tolower(trimws(ne_pops_exists)),
    nc_clean = tolower(trimws(nc_pops_exists))
  )

kobo_flagged <- psize_data %>%
  mutate(
    has_ne = ne_clean == "ne_available",
    has_nc = nc_clean == "yes"
  )

taxon_summary <- kobo_flagged %>%
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

taxon_summary %>% count(data_combination)
unique(tolower(kobo.3$popsize_data))

kobo.3 %>%
  filter(grepl("yes", popsize_data, ignore.case = TRUE)) %>%
  count(ne_pops_exists, nc_pops_exists)

kobo.3$ne_pops_exists
ne_pop_cols <- names(kobo.3)[grepl("^Ne_pop", names(kobo.3))]

kobo.3[ne_pop_cols] <- lapply(kobo.3[ne_pop_cols], function(x) {
  x <- as.numeric(x)
  x[x == -999] <- NA
  return(x)
})

summary(kobo.3[ne_pop_cols])

info_to_check <- check_n_pops %>%
  full_join(check_taxon_names) %>%
  full_join(missing_info) %>%
  full_join(dp_other_comments) %>%
  full_join(extinct_pop) %>%
  full_join(extant_NA) %>%
  full_join(extinct_NA) %>%
  select(name_assessor, taxon, issue)

write.csv(
  info_to_check,
  file = paste0("info_to_check_", Sys.Date(), ".csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

kobo.cleaned <- kobo.3
