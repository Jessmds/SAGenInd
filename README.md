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
- `R/03_pm_indicator.R`  
- `R/04_ne500_indicator.R`  
- `R/05_additional_analyses.R`  
  
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
2. Import the .xlsx file into Kobotoolbox following [these instructions](https://support.kobotoolbox.org/new_form.html). Check [Kobotoolbox documentation](https://support.kobotoolbox.org/welcome.html) for further details on how to deploy and use it.


Once all data have been compiled, export the Kobo dataset as a **CSV** with “values and headers” in **XML format**; this export option is required for the R code to recognise column names consistently.

## 3. Analysis workflow: how to use the code

The analysis is organised into a sequence of phases. Each phase is documented in the Quarto file and implemented in a corresponding R script for users who want to run or adapt parts of the pipeline.

### 3.1 Data export and import (Section 1; `01_import_data.R`)

- Import the Kobo CSV into R (e.g. using `read.csv` with the appropriate separator).  
- Verify that key fields (assessor name, genus, species, taxonomic order, validation status, etc.) are present and correctly read.  
- Filter to the focal taxonomic group (e.g. mammals) and create convenience fields (e.g. a combined `taxon` column for genus–species–subspecies).

### 3.2 Quality checks (Section 2; `02_quality_checks.R`)

- Identify and summarise missing or inconsistent values in critical fields (taxon names, taxonomic group, population counts, etc.).  
- Flag records with potential issues and export a CSV listing these cases so assessors can revise or confirm them.  
- Remove records flagged as “not approved” and create a cleaned dataset for indicator estimation.

### 3.3 Calculating the PM indicator (Section 3; `03_pm_indicator.R`)

- Derive historical and current numbers of populations per taxon from the Kobo responses.  
- Compute the proportion of populations maintained (PM) for each taxon and summarise across taxa.  
- Explore PM variation by Red List categories, realms, endemism status, and other attributes; generate summary tables and figures used in the manuscript.

### 3.4 Calculating the Ne 500 indicator (Section 5; `04_ne500_indicator.R`)

- Subset records with available population size data at species or population level.  
- Convert categorical census ranges to numeric values and unify point and range estimates.  
- Adjust census estimates for transboundary species (e.g. scaling to account for the proportion of the population in South Africa).  
- Convert census size (Nc) to Ne using multiple Nc:Ne ratios and compute the proportion of populations with Ne > 500.  
- Identify species whose overall Ne is < 500 and treat them appropriately when computing the indicator.

### 3.5 Additional outputs (Section 4 and others; `05_additional_analyses.R`)

- Generate plots and tables illustrating indicator values by Red List category, realm, and other groupings.  
- Produce diagnostic summaries, such as coverage of historical vs current population data or lists of taxa with specific data combinations.

## 4. How to run the pipeline

### Option A: Run the Quarto document

1. Place your exported Kobo CSV in the same directory as `genetic-indicator-code-3.qmd` or update the file path in the import section.  
2. Open the qmd in RStudio (or another editor) and render to HTML.  
3. Follow the sections in order; each one explains the purpose of the code and how intermediate objects feed into the indicators.

### Option B: Run the modular R scripts

1. Save your Kobo export into the project’s data directory (or update paths inside the scripts).  
2. Run the scripts in order:
   ```r
   source("R/01_import_data.R")
   source("R/02_quality_checks.R")
   source("R/03_pm_indicator.R")
   source("R/04_ne500_indicator.R")
   source("R/05_additional_analyses.R")
   ```
3. Adapt filters, thresholds, or indicator summaries to match your focal taxon or national context.

## 5. Adapting the workflow

The workflow is designed to be reusable for other taxa or countries:

- Replace the input Kobo export with one from a different project while maintaining the same core structure.  
- Modify or extend the quality checks to account for taxon-specific issues.  
- Adjust Nc:Ne conversion assumptions or indicator reporting formats as needed.

Users are encouraged to treat this repository as both a case study (mammals in South Africa) and a template for implementing the indicators in other contexts.
