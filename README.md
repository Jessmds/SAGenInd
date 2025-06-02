# South African Genetic Indicator Quantification
This repository has been created to help facilitate the calculation of population genetic indicators for South African biodiversity assessments. The code builds upon that developed for a multinational genetic indicator study (https://github.com/AliciaMstt/GeneticIndicators), but has been modified for complete taxon assessments and to generate the specific statistics and visuals needed for SA's National Biodiversity Assessment. 

The code presented here was developed for South Africa's first complete taxon assessed - Mammals.  This work was greatly facilitated by the coordination of Endangered Wildlife Trust, who were responsible for the Mammal's Regional Red List Re-assessments. Access to experts through online workshops, emails, and more, greatly enabled the speedy collection of the necessary data on population numbers, dispersal buffers, etc. 

For general information on guidance materials associated with these genetic indicators, please refer to https://ccgenetics.github.io/guidelines-genetic-diversity-indicators/.

## 1. Genetic Indicators

## 2. Online data collection form using Kobotoolbox
Kobotoolbox is a free and open source tool for data collection. It allows to easily develop digital data collection forms that work on both mobile devices and web browsers. Data can be collected from different devices and people, and is accessible through the KoboToolbox interface. This data can then be downloaded into multiple formats for use in applications such as Excel, R, Phyton or GIS software.

## 2.1 Koboform:
We built a Kobo form for collecting the needed raw data to estimate de Genetic Diversity Indicators mentioned above, as well as species taxonomic information and assessor's and country information.

You can see a dummy example of how the online form looks once it is deployed in Kobo here: https://ee.kobotoolbox.org/preview/2KDHEWrb. Notice that this form is just an example and it can NOT be used to collect real data.

If you want to use this form to collect data for your country or desired species, you can contact Alicia Mastretta-Yanes (amastretta@conabio.gob.mx) to get access to the data-collection form where other teams are collecting data. Alternatively you can deploy your own version of the form in Kobotoolbox as follows:

Download the file (kobo_form.xlsx) from this repository, which is the .xlsx version of the Kobo form.
Import it to Kobotoolbox following these instructions.
Check Kobotoolbox documentation for further details on how to deploy and use it. 

# 3. Modified scripts to process the kobo output and estimate the indicators
Note: original R code stems from https://github.com/AliciaMstt/GeneticIndicators

