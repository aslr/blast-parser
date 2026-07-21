//
//  KrakenParse.swift
//  blast-parser
//
//  Created by João Varela on 31/05/2026.
//

import Foundation
import ArgumentParser

struct ParseKraken: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parses a Kraken2 counts report to determine which sequences should be validated by BLASTN.",
        usage: "blast_parser parse --report <report> --classification <classification> --sequences <sequences> [--output <output>] [--asvformart <asvformat>] [--max-sequences-per-bin <max-sequences-per-bin>]",
        aliases: ["prsk"]
    )
    
    @Option(name: [.short, .customLong("report")],
            help: "Path to Kraken2 counts report to be parsed.")
    var report:String
    
    @Option(name: [.short, .customLong("classification")],
            help: "Path to the Kraken2 taxonomic assignment file.")
    var classification:String
    
    @Option(name: [.short, .customLong("asvformat")],
            help: "ASV format file. It can be either standard (5 columns: U/C sequenceID taxon(taxID) length LCA) or epi2me (6 columns: U/C sequenceID taxID length LCA lineage). [OPTIONAL, default = standard]")
    var asvFormat:String?
    
    @Option(name: [.short, .customLong("sequences")],
            help: "Path to the sample sequences file. It can be either a fasta file with the .fa or .fasta extension or a fastq file with the .fastq extension.")
    var sequences:String
    
    @Option(name: [.short, .customLong("output")],
            help: "Name of the output file. [OPTIONAL]")
    var outputFile:String?
    
    @Option(name: [.short, .customLong("max-sequences-per-bin")],
            help: "Maximum number of sequences per bin. [OPTIONAL, default = 10]")
    var maxSequencesPerBin:Int?
    
    mutating func run() throws {
        guard let parser = KrakenParser(report: report,
                                        classification: classification,
                                        sequences: sequences) else {
            throw ValidationError("Invalid path to an input file.")
        }
        
        if let sequencesPerBin = maxSequencesPerBin {
            parser.sequencesPerBin = sequencesPerBin
        }
        
        try parser.parseReport()
        try parser.printReport(to: outputFile)
        try parser.parseASVs(asvFormat: asvFormat)
        try parser.printParsedClassification(to: outputFile)
        try parser.parseSequences()
        try parser.printParsedSequences(to: outputFile)
    }
}
