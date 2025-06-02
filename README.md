# South African Genetic Indicator Quantification
This repository has been created to help facilitate the calculation of population genetic indicators for South African biodiversity assessments. The code builds upon that developed for a multinational genetic indicator study (https://github.com/AliciaMstt/GeneticIndicators), but has been modified for complete taxon assessments and to generate the specific statistics and visuals needed for SA's National Biodiversity Assessment. 

The code presented here was developed for South Africa's first complete taxon assessed - Mammals.  This work was greatly facilitated by the coordination of Endangered Wildlife Trust, who were responsible for the Mammal's Regional Red List Re-assessments. Access to experts through online workshops, emails, and more, greatly enabled the speedy collection of the necessary data on population numbers, dispersal buffers, etc. 

For general information on guidance materials associated with these genetic indicators, please refer to https://ccgenetics.github.io/guidelines-genetic-diversity-indicators/.

## 1. Genetic Indicators

## 2. Online data collection form using Kobotoolbox
[Kobotoolbox](https://kf.kobotoolbox.org/) is a free and open source tool for data collection. It allows to easily develop digital data collection forms that work on both mobile devices and web browsers. Data can be collected from different devices and people, and is accessible through the KoboToolbox interface. This data can then be downloaded into multiple formats for use in applications such as Excel, R, Phyton or GIS software.

## 2.1 Kobo Form:
We built a Kobo form for collecting the needed raw data to estimate the Genetic Diversity Indicators mentioned above. The template for this data collection form can be accessed (link here).

If you would like to start your own projects that can feed into this greater dataset, you can either contact Dr Jessica da Silva (j.dasilva@sanbi.org.za) to gain access to the project or **you can download the template file**, which is the .xlsx version of the Kobo form: 

1. Download the existing template from [here](https://github.com/user-attachments/files/20548476/Updated.SA.Genetic.Indicator.Data.Collection.form.xlsx)     
2. Import the .xlsx file into Kobotoolbox following [these instructions](https://support.kobotoolbox.org/new_form.html). Check [Kobotoolbox documentation](https://support.kobotoolbox.org/welcome.html) for further details on how to deploy 
         and use it.


# 3. Modified scripts to process the kobo output and estimate the indicators
**Note: original R code stems from https://github.com/AliciaMstt/GeneticIndicators**. The code below has been modified to suit the specific needs of this project.





