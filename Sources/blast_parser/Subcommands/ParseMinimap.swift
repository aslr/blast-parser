//
//  ParseMinimap.swift
//  blast-parser
//
//  Created by João Varela on 31/05/2026.
//

import ArgumentParser

struct ParseMinimap: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parses a minimap2 output tsv file containing a header row with the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy and then outputs files containing selected sequences in fastq and/or fasta format to be remapped by minimap2 with other databases or in fasta format to be the input to BLASTN and/or a read count stats file per taxon found. Warning: an error will be generated if no output file is specified.",
        usage: "blast-parser parse-minimap --input <input> --reads <fastq-file> [--output <fastq-output>] [--fastaOutput <fasta-output>] [--stats-output <stats-output>] [--hits-per-bin <hits-per-bin>]",
        aliases: ["prsm"] )
    
    @Option(name: [.short, .customLong("input")],
            help: "Path to the minimap2 output table containing the following columns: QueryID, Reference_ID, Alignment_Score, Alignment_Length and Taxonomy")
    var input:String
    
    @Option(name: [.short, .customLong("reads")],
            help: "Path to the fastq file containing the reads that were mapped with minimap2.")
    var reads:String
    
    @Option(name: [.short, .customLong("fastq-output")],
            help: "Path to the output fastq file. [OPTIONAL]")
    var output:String?
    
    @Option(name: [.short, .customLong("fasta-output")],
            help: "Path to the output fasta file. [OPTIONAL]")
    var fastaOutput:String?
    
    @Option(name: [.short, .customLong("stats-output")],
            help: "Path to the output file containing the read count stats per taxon. [OPTIONAL]")
    var statsOutput:String?
    
    @Option(name: [.short, .customLong("hits-per-bin")],
            help: "Maximum number of reads to include in each taxon bin. [OPTIONAL, default = 5")
    var hitsPerBin:Int = 5
    
    mutating func run() throws {
        guard let parser = MinimapParser(path: input,
                                         readsPath: reads,
                                         hitsPerBin: hitsPerBin) else {
            throw ValidationError("Unable to parse minimap2 output file as no valid file was found.")
        }
        parser.fastqOutputPath = output
        parser.fastaOutputPath = fastaOutput
        parser.statsOutputPath = statsOutput
        try parser.parse()
        try parser.print()
    }
}
