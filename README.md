# South African Genetic Indicator Quantification
This repository has been created to help facilitate the calculation of population genetic indicators for South African biodiversity assessments. The code builds upon that developed for a multinational genetic indicator study (see https://github.com/AliciaMstt/GeneticIndicators; Mastretta-Yanes, da Silva et al. 2024), but has been modified for complete taxon assessments and to generate the specific statistics and visuals needed for SA's National Biodiversity Assessment. 

* Mastretta-Yanes\*, A., da Silva\*, et al. 2024. **Multinational evaluation of genetic diversity indicators for the Kunming-Montreal Global Biodiversity Monitoring framework**.  *Ecology Letters* 27 (7): e14461. https://doi.org/10.1111/ele.14461

The code presented here was developed for **South Africa's first complete taxon assessed - Mammals**.  This work was greatly facilitated by the coordination of **Endangered Wildlife Trust**, who were responsible for the mammal's regional IUCN Red List Re-assessments. Access to experts through online workshops, emails, and more, greatly enabled the speedy collection of the necessary data on population numbers, dispersal buffers, etc. 

For general information on guidance materials associated with these genetic indicators, please refer to https://ccgenetics.github.io/guidelines-genetic-diversity-indicators/.

## 1. Genetic Indicators

## 2. Online data collection form using Kobotoolbox
[Kobotoolbox](https://kf.kobotoolbox.org/) is a free and open source tool for data collection. It allows to easily develop digital data collection forms that work on both mobile devices and web browsers. Data can be collected from different devices and people, and is accessible through the KoboToolbox interface. This data can then be downloaded into multiple formats for use in applications such as Excel, R, Phyton or GIS software.

## 2.1 Kobo Form:
We built a Kobo form for collecting the needed raw data to estimate the Genetic Diversity Indicators mentioned above. The template for this data collection form can be accessed (link here).

If you would like to start your own projects that can feed into this greater dataset, you can either contact Dr Jessica da Silva (j.dasilva@sanbi.org.za) to gain access to the project or **you can download the template file**, which is the .xlsx version of the Kobo form: 

1. Download the existing template from [here](https://github.com/Jessmds/SAGenInd/blob/main/SA-Genetic-Indicator-Data-Collection-Form.csv)
2. Import the .xlsx file into Kobotoolbox following [these instructions](https://support.kobotoolbox.org/new_form.html). Check [Kobotoolbox documentation](https://support.kobotoolbox.org/welcome.html) for further details on how to deploy 
         and use it.


# 3. Modified scripts to process the kobo output and estimate the indicators
**Note: original R code stems from https://github.com/AliciaMstt/GeneticIndicators**. The code for this project has been modified to suit the specific needs of this project. It is brokwn down into various phases:

1. [Data Import](https://github.com/Jessmds/SAGenInd/blob/main/Data%20Import)
2. [quality_check](https://github.com/Jessmds/SAGenInd/blob/main/quality_checks): looks for common sources of error and flags those records manual revision by the assessors who capture data from each country. The output is a file showing the records that need manual review or corrections, if any.

* [2\_cleaning](https://aliciamstt.github.io/GeneticIndicators/2_cleaning.html): corrects the errors detected by `1_quality_check.Rmd, based on the feed back from the people who collected the data. Corrections are done within this script to ensure reproducibility. The output is a clean kobo file that can be used for analyses. [.Rmd file here](./2_cleaning.Rmd).
3. 





