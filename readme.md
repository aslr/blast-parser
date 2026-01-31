//
//  Readme.md
//  blast_parser
//
//  Created by João Varela on 21/10/2024.
//

# `blast_parser`

## Abstract
This is an Xcode project written in Swift and C to build a CLI tool to bridge the Kraken2 taxonomic assignment of Nanopore sequences, so that these assignments can be validated by BLASTn searches. In this new version (0.4.0), it can also be used for validating Qiime 2 denoised ASVs and merge files from different classifiers and databases into a single read counts file and respective taxonomies. In this way, you can compare the results of different classifiers and databases as long as the representative sequence file has the same sequences. 

## Background
### Data explosion
Because of the explosion of sequencing data enabled by massive parallel sequencing (MPS) / next-generation sequencing (NGS), there has been a growing need to have bioinformatic pipelines able to analyze this deluge of sequencing data in a fast manner. However, speed and accuracy often do not go together.

### Metagenomics and the need for taxonomic assignment
In the beginning of this revolution, genomics, or the study of genomes, was focused on samples of known biological origin. However, with the introduction of MPS, the study of all the genomes present in an environmental sample became possible. This led to the advent of metagenomics. However, that created the need for assigning the biological origin of each DNA sequence retrieved from a sample.

### Use of marker genes to assign the biological origin of DNA sequences
Specific genes are often used to assign the biological origin of DNA sequences retrieved from a sample. Although you potentially could do this with any genomic sequence, in order to classify a sequence as belonging to a given organism, we need to use tools that are able compare that unknown sequence with known sequences present in databases. However, these databases are not comprehensive enough to contain all possible genes from every organism. **If the unknown sequence cannot be matched to a similar sequence in the database, then the assignment will fail. The unknown sequence will remain "unclassified".** Therefore, databases tend to contain specific marker genes. These marker genes should be present in all organisms, being often called "universal". The sequence of these marker genes are often used as "barcodes" to identify a given organism. Often used marker genes are the 16S ribosomal RNA gene for prokaryotes, 18S ribosomal RNA gene for eukaryotes and ITS (internal transcribed spacer) for fungi and algae. However, plastidial (e.g., *rbc*L), and mitochondrial (e.g., *cox*1) marker genes are also used. 

### Accuracy of taxonomic assignment of metagenomic sequences
For the most part, current pipelines used to classify taxonomically the biological origin of a given bacterial sequence are accepted as having a good accuracy. This is due to the fact that a large effort has been made by teams who wanted to study the human gut microbiota and its impact on our health. **Accuracy** is often measured by using DNA samples of a mock community with a known composition. If the sequencing retrieves a taxonomic composition similar enough to what is expected, then we can know the accuracy of the pipeline. 

### Poor accuracy of current pipelines for eukaryotic sequences
However, the same cannot be said when you want to analyze eukaryotic sequences and assign their most probable biological origin. Unlike the prokaryotic marker gene databases, current databases lag behind in their accuracy in assigning the correct taxonomic classification for eukaryotic sequences. This is a limitation caused by a set of factors that make this task very difficult, namely:

1. The enormous biodiversity of eukaryotes
2. Eukaryotes have much larger genomes than prokaryotes
3. Eukaryotes can contain one or more organellar genomes of eukaryotic and/or prokaryotic origin
4. Eukaryotic genes are often interrupted by introns, making the assignment of specific sequences to a gene quite challenging for automated pipelines
5. Many eukaryotes have never been sequenced resulting in highly incomplete databases
6. Relatively comprehensive databases like GenBank often contain sequences with wrong taxonomical assignments
7. Highly curated databases are often not comprehensive enough to be used for the classification of all *metagenomic* sequences present in a database

There are, however, some initiatives to correct this such as https://unieuk.net but they  are still in their infancy. In the meantime, we need to make do with what we have.

### Taxonomic assignment of metagenomic sequences
Taxonomy, since the efforts made by Carl Linnaeus in the 18th century, used a hierarchical system to classify the enormous diversity of known organisms. This system uses hierarchical *taxa* (plural of *taxon*). High ranking taxa contain other taxa with a lower ranking. Major taxa are from higher to lower ranking:

1. Domain (named as Superkingdom in some databases)
2. Phylum (sometimes named as Division by botanists and mycologists)
3. Class
4. Order
5. Family
6. Genus
7. Species

### DNA sequencing platforms
Metagenomic sequences can be processed via different platforms, which have advantages and disadvantages. The most common used platform is Illumina, which displays a high accuracy regarding their sequencing data. However, it has the disadvantage of generating short reads (often generating sequences with sizes of less than 300 base pairs that only span a small part of the marker gene sequence). These short reads may not contain enough information to assign it to a specific organism down to the species level. Actually, most current automated pipelines do so only down to the genus level. Therefore, other platforms generating longer reads have been created. One of them is Nanopore. This latter platform is able to generate much larger sequences, being able to sequence whole marker genes in one go. Although the Nanopore sequencing platform can generate longer reads, it often lacks the accuracy of the short-read technologies, being known to be more error prone than, for example, Illumina. However, this technology has come a long way and has reduced this error rate quite considerably.

### Pipelines for taxonomic assignment of Nanopore long reads
Current pipelines contain the following steps:

1. A **quality assessment** step of the generated sequences as the generated fastq files contain quality scores for each nucleotide in the sequence
2. A **trimming** step to remove low quality sequences that can confound the analyses to be performed downstream
3. A **classification** step, which often includes a counting step in order to quantify the number of reads assigned to a given taxon

As classifiers, tools like **Kraken2** and **minimap2** are used to classify the generated sequences against  databases that have been curated to contain sequencing information of eukaryotic genes. Currently, there are several available databases, but the one that seems to generate the best assignments is the [SILVA](https://www.arb-silva.de) database.

**Kraken2** is a classifier that uses a k-mer counting algorithm to assign a given sequence to a taxon. The more nucleotides it is able to assign to a given taxon, the more accurate the assignment will be. This has the advantage of being much faster than tools such as **minimap2** or **BLASTn** that use alignment-based algorithms to assign a given sequence to a taxon. However, Kraken2 has the disadvantage of not being as sensitive and accurate as alignment-based tools.

Currently, the golden standard is BLASTn, which can be used to search for sequence matches in the largest DNA sequence databases at NCBI. However, the large size of these databases makes the search process quite long and impractical when classifying millions of sequences from each environmental sample. Thus, current classifiers often use far less comprehensive databases (e.g, SILVA, PR2 and UNITE databases), which have, however, the advantage of having been manually curated by experts of the field.

### Accuracy of the current pipelines

As I am interested in working with eukaryotic microalgae and their eukaryotic predators and parasites, which can crash industrial microalgal cultures, we have generated sequencing data using different marker genes, namely 16S, 18S and ITS using Illumina short reads. In general, mostly due to the huge effort recently put into the Greengenes2 database, the assignment of 16S sequences seems to be quite accurate. However, the same cannot be said for eukaryotic sequences. Very often sequences that are assigned to be of "fungal" origin using Kraken2 and the database yielding the best results (i.e., SILVA) turn out to be quite inaccurate and even internally inconsistent. A quick search using BLASTn reveals that sequences to be of algal origin, in particular of a microalga we know that is present in that sample in large numbers. The use of minimap2 and the current manually curated databases often does not help either, because very often similar inaccurate assignments are made because the tools can only match against the most similar sequence present in the database. If the latter is not comprehensive enough, the tool will assign the sequence to the wrong taxon.

### What to do?
The best course of action will be to generate the most comprehensive, accurate databases to classify these eukaryotic sequences, as the authors working on the UNIEUK, PR2 and UNITE databases are trying to do. In addition, tools need to be written to support the accurate assignment of eukaryotic sequences using these databases, especially when working with long reads.

However, if we want to solve this problem right now, we need to find alternative strategies until these databases can become as comprehensive as required by the eukaryotic biodiversity we can find in samples coming from microalgal cultures.

### A possible alternative strategy
In spite of the inaccuracy found in the assignments made by Kraken2 using Nanopore reads, I could find that most sequences assigned to a specific (wrong) taxon, when validated by submitting them to the NCBI eukaryotic database using BLASTn, the correct taxon assignment was often the same (**but not always!**). Therefore, it seems as though Kraken2 can be used as an intermediate step to cluster the sequences into "bins" of closely related sequences. In a second step, several sequences of each bin can be blasted to confirm the assignment made, accelerating the process of validating the assignment using different tools and databases. If the assignment is correct, it should be internally and phylogenetically consistent. The same strategy can be used for other pipelines, such as using DADA2 to obtain denoised ASVs for Illumina reads and then validate them with BLASTn searches.


## `blast_parser`: What it does

`blast_parser` is a tool Catarina Alexandre and I started writing in Swift and C, which runs natively on MacOS, both Intel or Apple Silicon chips. A possible port to Linux might be considered. This tool does the following:

1. It imports the new [taxonomy database](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/) from NCBI containing the full lineages of each taxon from domain to species from the file `rankedlineage.dmp` into a CSV file using the `import` subcommand.
2. It re-exports the *imported* CSV file into a PostGresSQL database using the lipq library using the `export` subcommand.
This database can then be queried using the generated taxID from the BLASTn output in order to generate the full taxonomic lineage.
3. It merges a Kraken 2 counts report with a BLASTn output table using the -outfmt option "6 qsedid pident length evalue bitscore score nident saccver stitle qcovs staxids sscinames sskingdoms" using the `merge` subcommand
4. It merges a Qiime 2 output table containing the denoised ASVs table together with its assigned taxonomy with a BLASTn output table where `-outfmt` = "6 qsedid pident length evalue bitscore score nident saccver stitle qcovs staxids sscinames sskingdoms" by using the `merge-qiime` subcommand
5. It generates a full taxonomic lineage from an NCBI taxonomic ID by querying the local PostGresSQL database, which can then be merged with Kraken2 or Qiime 2 DADA2 output tables.
6. It merges output files generated by different classifiers, including a BLASTn output file, into a single read count file as long as these output files contain the same representative sequences. At the moment, the merge of more than one classifier is only implemented for the merge-qiime subcommand.

## `blast_parser`: New capibilities with version 0.6.1 and later

1. `blast_parser` using the subcommand `parse-minimap` is now able to use parse and join Nanopore long reads into bins with the same classification carried out by minimap2 and then generate a representative reads file in FASTA or FASTAQ format to be reclassified by minimap2 using different databases
2. `blast_parser` using the subcommand `merge-minimap` is now able to merge the classification carried out by BLAST+ and NCBI core_nt database with the classification output of minimap2 using different databases. This allows for checking the congruency and accuracy of different classifiers according to their alignment scores and lengths.
