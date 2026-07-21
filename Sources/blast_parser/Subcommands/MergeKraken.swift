//
//  KrakenMerge.swift
//  blast-parser
//
//  Created by João Varela on 31/05/2026.
//

import Foundation
import ArgumentParser

struct MergeKraken: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Merges a Kraken2 counts report with the best hits of a BLAST search.",
        usage: "blast-parser merge --asvs <asvs> --blasthits <blasthits> --lineage-db <lineage-db>  [--parsed-taxonomy <parsed-taxonomy>] [--output <output>] [--hits-per-asv <hits-per-asv>] [--sort <sort>]",
        aliases: ["mrgk"]
    )
    
    @Option(name: [.short, .customLong("asvs")],
            help: "Path to the Kraken2 counts output file of the parse subcommand.")
    var asvs:String
    
    @Option(name: [.short, .customLong("blasthits")],
            help: "Path to the BLAST output file using a 13 columns format with following order: qsedid pident length evalue bitscore score nident saccver stitle qcovs staxids sscinames sskingdoms.")
    var blasthits:String

    @Option(name: [.customShort("l"), .customLong("lineage-db")],
        help: "Path to the imported ranked lineage database in CSV format.")
    var taxonomyDB:String
    
    @Option(name: [.short, .customLong("parsed-taxonomy")],
            help: "Path to the Kraken2 output file of the parse subcommand containing a parsed hierarchical taxonomy. [OPTIONAL]")
    var parsedTaxonomy:String?
    
    @Option(name: [.short, .customLong("output")],
            help: "Name of the output file. [OPTIONAL]")
    var outputFile:String?
    
    @Option(name: [.customLong("hits-per-asv")],
            help: "Maximum number of sequences per bin. [OPTIONAL, default = 1]")
    var hitsPerAsv:Int?
    
    @Option(name: [.short, .customLong("sort")],
            help: "Sorting order of the output file, which can be either pident, bitscore or evalue. [OPTIONAL, default = bitscore]")
    var sort:String?
    
    mutating func run() throws {
        guard let parser = BlastKrakenOutputParser(path: blasthits,
                                                   asvs: asvs,
                                                   taxonomy: parsedTaxonomy)
        else {
            throw ValidationError("Could not find a valid Kraken2 counts file to be merged with the BLAST hits file.")
        }
        
        if let hitsPerAsv = self.hitsPerAsv {
            parser.hitsPerASV = hitsPerAsv
        }
        
        if let sort = self.sort {
            if let criterion = BlastHit.SortCriterion(rawValue: sort) {
                try parser.parse(lineageDBPath: taxonomyDB,
                                 criterion: criterion)
            } else {
                throw ValidationError("Wrong criterion for sorting the output file. Please use either pident, bitscore or evalue.")
            }
        } else {
            try parser.parse(lineageDBPath: taxonomyDB)
        }
        
        try parser.print(to: outputFile)
    }
}
