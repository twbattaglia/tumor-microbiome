## A pan-cancer analysis of the microbiome in metastatic cancer

This repository contains the code pertinent to our publication. Please refer to materials and methods section of the article for details.
>Thomas W. Battaglia, Iris L. Mimpen, Joleen J.H Traets, Arne van Hoeck, Laurien J. Zeverijn, Birgit S. Geurts, Gijs F. de Wit, Michaël Noë, Ingrid Hofland, Joris L. Vos, Sten Cornelissen, Maartje Alkemade, Annegien Broeks, Charlotte L. Zuur, Edwin Cuppen, Lodewyk Wessels, Joris van de Haar, Emile Voest
, A pan-cancer analysis of the microbiome in metastatic cancer, Cell (Accepted)

## Abstract
Microbial communities are resident to multiple niches of the human body and are important modulators of the host immune system and responses to anticancer therapies. Recent studies have shown that complex microbial communities are present within primary tumors. To investigate the presence and relevance of the microbiome in metastases, we integrated mapping and assembly-based metagenomics, genomics, transcriptomics, and clinical data of 4,160 metastatic tumor biopsies. We identified organ-specific tropisms of microbes, enrichments of anaerobic bacteria in hypoxic tumors, associations between microbial diversity and tumor-infiltrating neutrophils, and the association of Fusobacterium with resistance to immune checkpoint blockade (ICB) in lung cancer. Furthermore, longitudinal tumor sampling revealed temporal evolution of the microbial communities and identified bacteria depleted upon ICB. Together, we generated a pan-cancer resource of the metastatic tumor microbiome which may contribute to advancing treatment strategies

## Pipeline
This analysis makes use of a Google Cloud (GCP) based Nextflow pipeline to process human-genome mapped CRAM files hosted on GCP. For more information regarding this pipeline, please see: https://github.com/twbattaglia/tumor-microbiome-nf

## Usage

To reproduce the analysis:

1. Clone this repository.
  ```
  git clone https://github.com/twbattaglia/tumor-microbiome
  ```
  
3. Install the required dependencies with renv.
  ```
  install.packages("renv")
  renv::restore()
  ```
4. Run code within the `mapping-analysis.Rmd` notebook.

## Analysis Overview
The analysis performed on includes:

- Data preprocessing
- Exploratory data analysis (EDA)
- Statistical analysis
- Results interpretation

## Files
The repository includes the following files:

- `data/`: Directory containing the dataset files.
- `results/`: Directory containing the results of the analysis.
- `mapping-analysis.Rmd`: Markdown file providing an overview of the mapping analysis.

## Contributors

- [Thomas W. Battaglia](https://github.com/twbattaglia) - [@twbattaglia](https://github.com/twbattaglia)

## License

This project is licensed under the [MIT License](LICENSE).

