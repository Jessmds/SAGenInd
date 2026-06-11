# South African Genetic Indicator Quantification

This repository has been created to help facilitate the calculation of population genetic indicators for South African biodiversity assessments. The code builds upon that developed for a multinational genetic indicator study (https://github.com/AliciaMstt/GeneticIndicators; Mastretta-Yanes, da Silva et al. 2024), but has been modified for complete taxon assessments and to generate the specific statistics and visuals needed for South Africa’s National Biodiversity Assessment.

- Mastretta-Yanes*, A., da Silva*, et al. 2024. Multinational evaluation of genetic diversity indicators for the Kunming-Montreal Global Biodiversity Monitoring framework. Ecology Letters 27 (7): e14461. https://doi.org/10.1111/ele.14461

The code presented here was developed for South Africa’s first complete taxon assessed – *Mammals* – and was greatly facilitated by the coordination of the Endangered Wildlife Trust, who were responsible for the mammal's regional IUCN Red List Re-assessments. Access to experts through online workshops, emails, and other interactions enabled rapid data collection on population numbers, dispersal buffers, and other key variables.

For general information on guidance materials associated with these genetic indicators, please refer [**`here`**](https://ccgenetics.github.io/guidelines-genetic-diversity-indicators/).

## Files in this repository

Quarto document that explains the indicators, describes the Kobo-based data collection, and provides step-by-step R code for importing, quality checking, and analysing the data (PM indicator, Ne 500 indicator, and additional outputs).
- `genetic-indicator-code-3.qmd`
   
Rendered HTML version of the Quarto document for users who prefer a web-based walkthrough.
- `genetic-indicator-code-3.html`
  
Modular R scripts corresponding to the main analysis phases described in the Quarto document. 
- `R/01_import_data.R`  
- `R/02_quality_checks.R`  
- `R/03_data_exploration.R`  
- `R/04_PM_indicator.R`  
- `R/05_Ne500_indicator.R`  
  
Example Kobo data collection template and any ancillary data/lookup tables, as described below.

## 1. Genetic indicators implemented

To help assess the genetic health of species and their populations, genetic diversity EBVs and indicators have been developed. Two indicators have been adopted into the Convention on Biological Diversity’s Global Monitoring Framework, and are implemented here:

- **Headline indicator (Goal A, Target 4): Proportion of populations with Ne > 500**  
  Often referred to as the **Ne 500 indicator**.

- **Complementary indicator (Target 4): Proportion of populations maintained within species**  
  Often referred to as the **PM indicator**.

The Quarto document and scripts show how these indicators are calculated from the Kobo data, including the assumptions used to convert census size (Nc) to Ne and how transboundary species are treated.

For a comprehensive review of the CBD’s Global Biodiversity Framework and these indicators, see da Silva et al. (2026).

## 2. Online data collection form using KoboToolbox

[Kobotoolbox](https://kf.kobotoolbox.org/) is a free and open source tool for data collection. It allows to easily develop digital data collection forms that work on both mobile devices and web browsers. Data can be collected from different devices and people, and is accessible through the KoboToolbox interface. This data can then be downloaded into multiple formats for use in applications such as Excel, R, Phyton or GIS software.

## 2.1 Kobo Form:
We built a Kobo form for collecting the needed raw data to estimate the Genetic Diversity Indicators mentioned above. The template for this data collection form can be accessed (link here).

If you would like to start your own projects that can feed into this greater dataset, you can either contact Dr Jessica da Silva (j.dasilva@sanbi.org.za) to gain access to the project or **you can download the template file**, which is the .xlsx version of the Kobo form: 

1. Download the existing template from [here](https://github.com/Jessmds/SAGenInd/blob/main/SA-Genetic-Indicator-Data-Collection-Form.csv)
2. Import the .xlsx file into Kobotoolbox following [these instructions](https://support.kobotoolbox.org/xlsform_with_kobotoolbox.html). Check [Kobotoolbox documentation](https://support.kobotoolbox.org/welcome.html) for further details on how to deploy and use it.


Once all data have been compiled, export the Kobo dataset as a **CSV** with “values and headers” in **XML format**; this export option is required for the R code to recognise column names consistently.

## 3. Analysis workflow: how to use the code

The analysis is organised into a sequence of phases. Each phase is documented in the Quarto file and implemented in a corresponding R script for users who want to run or adapt parts of the pipeline.

### 3.1 Data import (Section 1; `01_data_import.R`)

- Import the Kobo CSV into R (currently via `read.csv` with comma-separated input).  
- Inspect the dataset structure and verify that core fields are present and correctly read, including assessor name, genus, species, taxonomic order, and validation status.  
- Filter the dataset to the focal taxonomic group and exclude records not approved for analysis.  
- Create a combined `taxon` field from genus, species, and subspecies/variety entries.  
- Derive an `endemic_status` field using species-level endemicity fields and population-level transboundary information.

### 3.2 Quality checks (Section 2; `02_quality_checks.R`)

- Standardise key numeric population fields by converting placeholder values such as `-999` to missing values and coercing them to integer format.  
- Trim whitespace and convert empty strings to `NA` across character fields.  
- Flag records with potential problems, including suspicious population counts, missing required metadata, unusual taxon name formatting, ambiguous “other” population definitions, and missing extant/extinct population values.  
- Summarise population-count distributions and inspect records with extinct populations or inconsistencies between historical and current population counts.  
- Export a CSV of flagged records for checking and produce a cleaned dataset (`kobo.cleaned`) for downstream analyses.

### 3.3 Data exploration (Section 3; `03_data_exploration.R`)

- Summarise whether assessments are at species or subspecies level.  
- Quantify completeness of extant and extinct population-count data across taxa.  
- Explore how assessors defined populations and tabulate common definition types.  
- Summarise the availability of population-size data (`popsize_data`), including species-level versus population-level information.  
- Generate diagnostic tables and figures showing data availability across taxonomic orders, Red List categories, and realms, and compare availability of `Ne` and `Nc` data.

### 3.4 Calculating the PM indicator (Section 4; `04_PM_indicator.R`)

- Subset taxa with both extant and extinct population counts available.  
- Calculate the Populations Maintained (PM) indicator for each taxon as the proportion of extant populations relative to total known extant plus extinct populations.  
- Summarise PM values by taxonomic group and evaluate threshold-based summaries (e.g. taxa below 0.75 or 0.25).  
- Test for differences in PM across taxonomic orders, endemism status, Red List categories, and realms.  
- Generate manuscript-ready tables and figures, including ranked PM plots, Red List comparisons, and summaries of historical versus current population change.

### 3.5 Calculating the Ne 500 indicator (Section 5; `05_Ne500_indicator.R`)

- Subset taxa with species-level or population-level census size data.  
- Convert categorical census-size ranges into numeric values and combine range- and point-based census estimates.  
- Adjust census values for transboundary taxa where only the South African fraction of the population was reported.  
- Convert census size (`Nc`) to effective population size (`Ne`) using alternative `Ne:Nc` ratios (0.1, 0.2, and 0.3), while prioritising directly supplied `Ne` values where available.  
- Reshape population-level estimates into long format, incorporate extinct populations as `Ne = 0`, and calculate the proportion of populations with `Ne > 500` for each taxon.  
- Combine species-level and population-level results, summarise national indicator values, test for differences across Red List categories, and generate tables and figures for the manuscript.

## 4. How to run the pipeline

### Option A: Run the Quarto document

1. Place your exported Kobo CSV in the same directory as the Quarto document, or update the file path in the data import section.  
2. Open the `.qmd` file in RStudio (or another editor that supports Quarto) and render it to HTML.  
3. Run the workflow sections in order, as each section builds on objects created earlier in the document.  
4. Check that the input filename, focal taxonomic filter, and any output paths match your local setup before rendering.

### Option B: Run the modular R scripts

1. Save your Kobo export in the project directory, or update the input file path in `01_data_import.R`.  
2. Run the scripts in order:
   ```r
   source("R/01_data_import.R")
   source("R/02_quality_checks.R")
   source("R/03_data_exploration.R")
   source("R/04_PM_indicator.R")
   source("R/05_Ne500_indicator.R")
   ```
3. Note that later scripts depend on objects created earlier in the workflow: `02_quality_checks.R` requires `kobo.2` from `01_data_import.R`, while both `03_data_exploration.R`, `04_PM_indicator.R`, and `05_Ne500_indicator.R` use `kobo.cleaned` created in `02_quality_checks.R`.  
4. Adapt the input filename, focal taxonomic filter, and any taxon-specific summaries or output paths to match your focal group or national context.
   
## 5. Adapting the workflow

The workflow is designed to be reusable for other taxa or countries:

- Replace the input Kobo export with a dataset from a different project, while keeping the same overall field structure or adjusting the import step accordingly.  
- Update the focal taxonomic filter in `01_data_import.R` to match the target group.  
- Modify the quality checks in `02_quality_checks.R` to account for taxon- or project-specific issues.  
- Extend the exploratory summaries in `03_data_exploration.R` if additional data-completeness diagnostics are useful.  
- Adjust the PM and Ne500 indicator logic, including Nc:Ne conversion assumptions, threshold values, and reporting formats, to suit the study system and national context.  

Users are encouraged to treat this repository as both a case study (mammals in South Africa) and a template for implementing the indicators in other contexts.
