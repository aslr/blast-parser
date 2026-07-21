//
//  MergeMinimap.swift
//  blast-parser
//
//  Created by João Varela on 31/05/2026.
//

import ArgumentParser

struct MergeMinimap: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Merges minimap2 output tsv files containing a header row with the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy with the best hits of a BLAST search. ",
        usage: "blast-parser merge-minimap --main-hits <main-hits> --blasthits <blasthits> --reads <fasta-file> --lineageDB <lineageDB> [--rep-hits <representative-hits>] [--o-merged <merged-file>] [--o-hitcounts <hitcounts-file>] [--sort <sort>]",
        aliases: ["mrgm"] )
    
    @Option(name: [.short, .customLong("main-hits")],
            help: "Path to the directory containing minimap2 output table main files separated by spaces. Each main table must contain the hits of all reads, should have the suffix '_classified.tsv' in its filename and should contain the following columns: QueryID, Reference_ID, Alignment_Score, Alignment_Length and Taxonomy.  The rest of the filename(s) must correspond to the sample ID(s) of the reads. The directory should be named as the database used to classify the reads as that will be used as a prefix to the corresponding column headers." )
    var mainHits:String
    
    @Option(name: [.short, .customLong("blasthits")],
            help: "Path to the directory containing the BLAST output files using a 13-columns format with following order: qsedid pident length evalue bitscore score nident saccver stitle qcovs staxids sscinames sskingdoms. The suffix of the files must be '_representative_blast.tsv'. The rest of the filename will be interpreted as the sample ID.")
    var blasthits:String
    
    @Option(name: [.customShort("l"), .customLong("lineage-db")],
        help: "Path to the imported ranked lineage database in CSV format.")
    var taxonomyDB:String
    
    @Option(name: [.short, .customLong("rep-hits")],
            help: "Path(s) to the directories containing minimap2 output table files separated by spaces. Each table must contain the hits selected by parse-minimap subcommand, should have the suffix '_representative_classified.tsv' in its filename and must contain the following columns: QueryID, Reference_ID, Alignment_Score, Alignment_Length and Taxonomy. The rest of the filename(s) must correspond to the sample ID(s) of the reads. Each directory should be named as the database used to classify the reads as that will be used as a prefix to the corresponding column headers.")
    var representativeHits:String?
    
    @Option(name: [.customShort("o"), .customLong("o-merged")],
            help: "Name of the merged output file containg all hits sorted by their queryIDs and respective taxonomic assignments. [OPTIONAL, default = (BLASTn output filename)_merged_output.tsv].")
    var outputMergedFile:String?
    
    @Option(name: [.customShort("h"), .customLong("o-hitcounts")],
            help: "Name of the hit counts file with the taxonomic assignment sorted by their hit counts in descending order [OPTIONAL, default = (BLASTn output filename)_hitcounts_output.tsv].")
    var outputHitCountsFile:String?
    
    @Option(name: [.short, .customLong("sort")],
            help: "Sorting order of the output file, which can be either pident, bitscore or evalue. [OPTIONAL, default = bitscore]")
    var sort:String?
    
    mutating func run() throws {
        guard let parser = BlastMinimapMultiFileOutputParser(path: blasthits,
                                                             mainHits: mainHits,
                                                             representativeHits: representativeHits) else {
            throw ValidationError("Unable to merge the minimap2 and BLASTn output files because at least one file could not be found or is invalid.")
        }
        
        parser.outputMergedFile = outputMergedFile
        parser.outputHitCountsFile = outputHitCountsFile
        
        if let sort = self.sort {
            if let criterion = BlastHit.SortCriterion(rawValue: sort) {
                try parser.parse(lineageDBPath:taxonomyDB, criterion: criterion)
            } else {
                throw ValidationError("Wrong criterion for sorting the output file. Please use either pident, bitscore or evalue.")
            }
        } else {
            try parser.parse(lineageDBPath: taxonomyDB)
        }
        try parser.merge(lineageDB: taxonomyDB)
        try parser.print()
    }
}
