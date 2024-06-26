# Helper functions for tumor-microbiome project

# Load required libraries
library(ggsci)
library(RColorBrewer)
library(patchwork)
library(ggpubr)
library(ggtree)
library(ggthemes)
library(picante)
library(entropart)
library(vegan)
library(scater)
library(NetCoMi)
library(mia)
library(breakaway)
library(bluster)
library(microViz)
library(clusterProfiler)
library(variancePartition)
library(miaViz)
library(survminer)
library(survival)
library(phyloseq)
library(microbiome)
require(tidyverse)


# Various functions for processing
# Import pathseq counts files
import_pathseq = function (filepath, metadata.in, level = "genus", count_feature = "unambiguous", minimum = 1) {
  message("Importing PathSeq files...")
  pathseq.import = filepath %>% 
    map_dfr(.id = "sampleId", function(x) data.table::fread(x, colClasses = c("taxonomy" = "character",
                                                                              "type" = "character",
                                                                              "name" = "character",
                                                                              "kingdom" = "character"))) %>% 
    filter(sampleId %in% row.names(metadata.in)) %>% 
    filter(type == level) 
  
  # Convert to phyloseq object
  message("Get NCBI taxonomic annotations...")
  ncbi.ids = unique(pathseq.import$tax_id)
  names(ncbi.ids) = ncbi.ids
  taxize.ids = suppressMessages(taxize::classification(ncbi.ids, db = 'ncbi'))
  taxize.ids.long = map_dfr(taxize.ids, .f = bind_rows, .id = "old_id")
  
  ncbi.ids.updated = taxize.ids.long %>% 
    filter(rank == level) %>% 
    rename(new_id = id) %>% 
    select(old_id, new_id) %>% 
    mutate(old_id = as.character(old_id))
  
  message("Replacing outdated annotations...")
  pathseq.import.fixed = pathseq.import %>% 
    mutate(tax_id = as.character(tax_id)) %>% 
    left_join(ncbi.ids.updated, by = c("tax_id" = "old_id"))
  
  # Convert to phyloseq object
  message("Converting counts to phyloseq...")
  otu.table = pathseq.import.fixed %>% 
    filter(unambiguous >= minimum) %>% 
    dplyr::select(new_id, unambiguous, sampleId) %>% 
    filter(!is.na(new_id)) %>% 
    group_by(sampleId, new_id) %>% 
    summarise(sum = sum(unambiguous)) %>% 
    pivot_wider(names_from = sampleId, values_from = sum, values_fill = 0) %>% 
    column_to_rownames("new_id") 
  
  # Get taxonomy table
  message("Converting taxonomy to phyloseq...")
  tax.table = taxize.ids.long %>% 
    select(-id) %>% 
    filter(rank %in% c("superkingdom", "phylum", "class", "order", "family", "genus")) %>% 
    pivot_wider(id_cols = old_id, names_from = rank, values_from = name) %>% 
    left_join(ncbi.ids.updated) %>% 
    select(-old_id) %>% 
    distinct(superkingdom, phylum, class, order, family, genus, new_id, .keep_all = T) %>% 
    as.data.frame() %>% 
    filter(!is.na(new_id)) %>% 
    column_to_rownames("new_id") %>% 
    rename(Kingdom = superkingdom,
           Phylum = phylum,
           Class = class,
           Order = order,
           Family = family,
           Genus = genus) %>% 
    as.matrix() 
  
  message(paste0("Detected ", nrow(otu.table), " taxa"))
  message(paste0("Detected ", ncol(otu.table), " samples"))
  
  SAMPLE = metadata.in %>% sample_data()
  OTU = otu_table(otu.table, taxa_are_rows = TRUE)
  TAX = tax_table(tax.table)
  
  pseq = phyloseq(OTU, TAX, SAMPLE)
  pseq.fil = prune_taxa(taxa_sums(pseq) > 0, pseq)
  
  return(pseq.fil)
}


# Function to import Bracken counts into phyloseq object
import_bracken = function (fileinput, metadata.in) {
  message("Importing Kraken2/Bracken files...")
  kraken2.import = fileinput %>% 
    map_dfr(.id = "sampleId", data.table::fread) %>% 
    as_tibble() %>% 
    filter(sampleId %in% row.names(metadata.in))
  
  # Convert to phyloseq object
  message("Get NCBI taxonomic annotations...")
  ncbi.ids = unique(kraken2.import$taxonomy_id)
  names(ncbi.ids) = ncbi.ids
  
  taxize.ids = suppressMessages(taxize::classification(ncbi.ids, db = 'ncbi'))
  taxize.ids.long = map_dfr(taxize.ids, .f = bind_rows, .id = "old_id")
  
  ncbi.ids.updated = taxize.ids.long %>% 
    filter(rank == "genus") %>% 
    rename(new_id = id) %>% 
    select(old_id, new_id) %>% 
    mutate(old_id = as.character(old_id))
  
  message("Replacing outdated annotations...")
  kraken2.import.fixed = kraken2.import %>% 
    mutate(taxonomy_id = as.character(taxonomy_id)) %>% 
    left_join(ncbi.ids.updated, by = c("taxonomy_id" = "old_id"))
  
  # Convert to phyloseq object
  message("Converting counts to phyloseq...")
  otu.table = kraken2.import.fixed %>% 
    dplyr::select(new_id, new_est_reads, sampleId) %>% 
    filter(!is.na(new_id)) %>% 
    group_by(sampleId, new_id) %>% 
    summarise(sum = sum(new_est_reads)) %>% 
    pivot_wider(names_from = sampleId, values_from = sum, values_fill = 0) %>% 
    column_to_rownames("new_id") 
  
  # Get taxonomy table
  message("Converting taxonomy to phyloseq...")
  tax.table = taxize.ids.long %>% 
    select(-id) %>% 
    filter(rank %in% c("superkingdom", "phylum", "class", "order", "family", "genus")) %>% 
    pivot_wider(id_cols = old_id, names_from = rank, values_from = name) %>% 
    left_join(ncbi.ids.updated) %>% 
    select(-old_id) %>% 
    distinct(superkingdom, phylum, class, order, family, genus, new_id, .keep_all = T) %>% 
    as.data.frame() %>% 
    filter(!is.na(new_id)) %>% 
    column_to_rownames("new_id") %>% 
    rename(Kingdom = superkingdom,
           Phylum = phylum,
           Class = class,
           Order = order,
           Family = family,
           Genus = genus) %>% 
    as.matrix() 
  
  message(paste0("Detected ", nrow(otu.table), " taxa"))
  message(paste0("Detected ", ncol(otu.table), " samples"))
  
  SAMPLE = metadata.in %>% sample_data()
  OTU = otu_table(otu.table, taxa_are_rows = TRUE)
  TAX = tax_table(tax.table)
  
  pseq = phyloseq(OTU, TAX, SAMPLE)
  pseq.fil = prune_taxa(taxa_sums(pseq) > 0, pseq)
  
  return(pseq.fil)
}


get_intersection = function(kraken2, pathseq, pcutoff = 1, kcutoff = 10){
  
  # For each sample, filter kraken2 based on the microbes found in pathseq
  kraken2.abun = abundances(kraken2) %>% as.data.frame() %>% rownames_to_column("Id")
  pathseq.abun = abundances(pathseq) %>% as.data.frame() %>% rownames_to_column("Id")
  
  # Iterate over samples in Kraken2 table
  pb <- progress_estimated(length(sample_names(kraken2)))
  
  filtered = sample_names(kraken2) %>% 
    map(.f = function(x){
      
      pb$tick()$print()
      to.fil = select(pathseq.abun, "Id" , x) %>% 
        filter(.data[[x]] >= pcutoff) %>% 
        pull(Id)
      
      select(kraken2.abun, "Id", x) %>% 
        filter(Id %in% to.fil) %>% 
        filter(.data[[x]] >= kcutoff) 
    }) 
  
  # Merge all tables together
  joined = filtered %>% 
    purrr::reduce(full_join, by = "Id") %>% 
    replace(is.na(.), 0)
  
  # Convert to phyloseq object
  mat = joined %>% 
    column_to_rownames("Id") %>% 
    as.matrix()
  
  # Add back to phylsoeq object
  results = kraken2
  otu_table(results) = otu_table(mat, taxa_are_rows = T)
  
  # Prune samples with no reads
  results = prune_samples(sample_sums(results)>0, results)
  results = prune_taxa(taxa_sums(results)>0, results)
  
  return(results)
}

# Run maaslin2
run_maaslin = function(pseq.in, 
                       transform = "LOG", 
                       analysis_method = "LM", 
                       normalization = "TSS", 
                       fixed_effects = NULL, 
                       random_effects = NULL, 
                       max_significance = 0.25, 
                       min_prevalence = 0.10, 
                       min_variance = 0.0, 
                       min_abundance = 0.0,
                       reference = c("primaryTumorLocation,CUP", "biopsySite,CNS")) {
  
  # get temporary directory
  tmp.dir = tempdir()
  
  # Format counts table
  pseq.in %>% 
    aggregate_taxa(level = "Genus") %>% 
    abundances() %>% 
    t() %>% 
    as.data.frame() %>% 
    rownames_to_column("ID") %>% 
    write_tsv(paste0(tmp.dir, "/maaslin2.counts.tsv"))
  
  # Format metadata
  meta(pseq.in) %>% 
    rownames_to_column("ID") %>% 
    write_tsv(paste0(tmp.dir, "/maaslin2.metadata.tsv"))
  
  # Run command
  library(Maaslin2)
  fit_data <- Maaslin2( input_data = paste0(tmp.dir, "/maaslin2.counts.tsv"), 
                        input_metadata = paste0(tmp.dir, "/maaslin2.metadata.tsv"), 
                        output = paste0(tmp.dir, "/outdir"), 
                        transform = transform,
                        normalization = normalization,
                        fixed_effects = fixed_effects,
                        random_effects = random_effects,
                        analysis_method = analysis_method,
                        standardize = T,
                        cores = 2, 
                        min_abundance = min_abundance,
                        min_prevalence = min_prevalence,
                        max_significance = max_significance,
                        plot_heatmap = F, 
                        plot_scatter = F,
                        reference = reference)
  
  
  # Import results
  results = read_tsv( paste0(tmp.dir, "/outdir/all_results.tsv"))
  sig_results = read_tsv( paste0(tmp.dir, "/outdir/significant_results.tsv"))
  
  # Return
  return(list(results = results, sig_results = sig_results))
  
}

# Regress out covariates
get_residuals = function(input.table, formula = c("primaryTumorLocation", "biopsySite")) {
  input.table.long = input.table %>% 
    pivot_longer(cols = -hmfSampleId, names_to = "signatures", values_to = "y") %>% 
    inner_join(meta(Hartwig)) %>% 
    left_join(select(immune.signatures, hmfSampleId, cd45)) %>% 
    #left_join(select(purple.data, hmfSampleId, tml, tmbPerMb, tmbStatus, tmlStatus)) %>% 
    as_tibble() 
  
  unique(input.table.long$signatures) %>% 
    map_dfr(.f = function(x) {
      input.table.long %>% 
        filter(signatures == x) %>% 
        tibble::column_to_rownames("hmfSampleId") %>% 
        glm(as.formula(paste("y", paste(formula, collapse=" + "), sep=" ~ ")), data = ., family = "gaussian") %>% 
        broom::augment() %>% 
        rename(hmfSampleId = `.rownames`,
               residual = `.resid`) %>% 
        mutate(diff = residual - mean(residual)) %>% 
        select(hmfSampleId, diff) %>% 
        mutate(signatures = x)
    }) %>% 
    pivot_wider(id_cols = hmfSampleId, names_from = signatures, values_from = diff) %>% 
    as.data.frame() 
}

