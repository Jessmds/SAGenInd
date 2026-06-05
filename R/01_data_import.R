# ============================================================
# 01_data_import.R
# Import Kobo dataset, load libraries, and verify structure
# ============================================================

library(tidyr)
library(dplyr)
library(utile.tools)
library(stringr)
library(ggplot2)
library(knitr)
library(tibble)
library(rstatix)

getwd()
list.files()

# Load dataset — update filename as needed
kobo <- read.csv(
  file = "SA_Mammal_Genetic_Indicator_Data_2024-2025.csv",
  sep = ",",
  header = TRUE
)

colnames(kobo)
ncol(kobo)
nrow(kobo)
str(kobo)
head(kobo)

kobo %>%
  filter(if_any(
    c(name_assessor, genus, species, Taxonomic_Order),
    ~ is.na(.) | str_trim(.) == ""
  )) %>%
  select(name_assessor, genus, species, Taxonomic_Order)

kobo %>%
  summarise(
    missing_name_assessor = sum(is.na(name_assessor) | str_trim(name_assessor) == ""),
    missing_genus         = sum(is.na(genus) | str_trim(genus) == ""),
    missing_species       = sum(is.na(species) | str_trim(species) == ""),
    missing_order         = sum(is.na(Taxonomic_Order) | str_trim(Taxonomic_Order) == "")
  )

kobo %>%
  filter(X_validation_status == "validation_status_not_approved") %>%
  select(name_assessor, genus, species, subspecies_variety)

kobo.1 <- kobo %>%
  filter(taxonomic_group == "mammal") %>%
  filter(X_validation_status != "validation_status_not_approved")

nrow(kobo.1)

kobo.1b <- kobo.1 %>%
  mutate(
    taxon = str_trim(utile.tools::paste(genus, species, subspecies_variety, na.rm = TRUE), "right")
  )

kobo.1b %>%
  select(taxonomic_group, genus, species, subspecies_variety, taxon)

kobo.2 <- kobo.1b %>%
  rowwise() %>%
  mutate(endemic_status = case_when(
    popsize_data == "data_for_species" & national_endemic == "yes" ~ "endemic",
    popsize_data == "data_for_species" & national_endemic == "no"  ~ "non_endemic",
    popsize_data == "yes" & any(c_across(num_range("transboundary_pop", 1:25)) == "yes_transboundary", na.rm = TRUE) ~ "non_endemic",
    popsize_data == "yes" & !any(c_across(num_range("transboundary_pop", 1:25)) == "yes_transboundary", na.rm = TRUE) &
      any(c_across(num_range("transboundary_pop", 1:25)) == "no_restricted", na.rm = TRUE) ~ "endemic",
    sa_endemic == "yes" ~ "endemic",
    sa_endemic == "no"  ~ "non_endemic",
    TRUE ~ NA_character_
  )) %>%
  ungroup()

kobo.2 %>% count(endemic_status)

endemism_status <- kobo.2 %>%
  filter(is.na(endemic_status)) %>%
  select(name_assessor, taxon, endemic_status)
endemism_status
