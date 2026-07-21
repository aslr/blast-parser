//
//  KrakenParser.swift
//  blast_parser
//
//  Created by João Varela on 12/07/2024.
//

import Foundation

final class KrakenParser {
    let classification:String
    let sequences:String
    let reportParser:KrakenReportParser
    let asvParser:KrakenASVParser
    let sequenceParser:KrakenSequenceParser
    let defaultReportSuffix = "parsed-output.tsv"
    let defaultClassificationSuffix = "parsed-classification.tsv"
    let defaultSequenceSuffix = "parsed-sequences.fasta"
    var sequencesPerBin = 10
    var asvs:[KrakenASV]?
    
    init?(report: String, classification: String, sequences: String) {
        self.classification = classification
        self.sequences = sequences
        
        guard let reportParser = KrakenReportParser(path: report)
            else { return nil }
        
        guard let asvParser = KrakenASVParser(path: classification)
            else { return nil }
        
        guard let sequenceParser = KrakenSequenceParser(path: sequences)
            else { return nil }
        
        self.reportParser = reportParser
        self.asvParser = asvParser
        self.sequenceParser = sequenceParser
    }
    
    /// Parses a Kraken2 count report
    func parseReport() throws {
        do {
            try reportParser.parse()
        }
        
        catch ReportParserError.invalidRank(let line, let taxon) {
            throw RuntimeError("ERROR: Invalid rank at \(line): \(taxon)")
        }
        
        catch {
            throw RuntimeError("Unknown error while trying to parse Kraken2 counts report.")
        }
    }
    
    /// Parses a Kraken2 ASV report with the assigned taxonomy and places
    /// each asv into a bin with the same classification
    /// - Parameters:
    ///     - asvFormat: use `standard` for the standard 5-column report or use `epi2me` for the 6-column report produced by the Epi2Me metagenomics package
    func parseASVs(asvFormat:String? = nil) throws {
        reportParser.sort()
        if let asvFormat {
            switch asvFormat {
            case "standard":
                try asvParser.parse(format: .standard)
            case "epi2me":
                try asvParser.parse(format: .epi2me)
            default:
                throw RuntimeError("Invalid ASV format.")
            }
        } else {
            try asvParser.parse()
        }
       
        asvs = asvParser.binArray.getASVs(sequencesPerBin: sequencesPerBin)
    }
    
    /// Retrieves the sequences with the IDs present in the asvs array
    func parseSequences() throws {
        guard let asvs = self.asvs
            else { throw RuntimeError("Invalid ASV file.") }
        sequenceParser.parse(asvs: asvs)
    }
    
    /// Writes a parsed report with the following format:
    /// lineNumber percentage reads assignedReads rank.abbreviation rank-variant rank-name taxID lineage"
    func printReport(to path:String? = nil) throws {
        guard let writer = FileWriter(path: path ?? reportParser.path,
                                      suffix: defaultReportSuffix) else {
            throw RuntimeError("Unable to open file for writing the Kraken2 parsed report due to a malformed path.")
        }
        let dataWriter = try writer.makeDataWriter()
        for line in reportParser.lines {
            dataWriter.write(line: line.getLine())
        }
        
        Console.writeToStdOut("Written report to \(dataWriter.url.path).")
    }
    
    /// Writes a parsed report with the following format:
    /// sequenceID length assignedReads taxID taxonomy
    func printParsedClassification(to path:String? = nil) throws {
        guard let asvs = self.asvs
            else { throw RuntimeError("Invalid ASV file.")}
        
        guard let writer = FileWriter(path: path ?? reportParser.path,
                                      suffix: defaultClassificationSuffix) else {
            throw RuntimeError("Unable to open file for writing the Kraken2 parsed taxonomic assignment report due to a malformed path.")
        }
        let dataWriter = try writer.makeDataWriter()
        for asv in asvs {
            dataWriter.write(line: asv.description)
        }
        
        Console.writeToStdOut("Written parsed classification to \(dataWriter.url.path).")
    }
    
    /// Writes a parsed report with the selected sequences in fasta format
    /// that will be searched by BLASTn
    func printParsedSequences(to path:String? = nil) throws {
        guard let writer = FileWriter(path: path ?? reportParser.path,
                                      suffix: defaultSequenceSuffix) else {
            throw RuntimeError("Unable to open file for writing the Kraken2 parsed sequences due to a malformed path.")
        }
        let dataWriter = try writer.makeDataWriter()
        for sequence in sequenceParser.sequences {
            dataWriter.write(line: ">" + sequence.sequenceID)
            dataWriter.write(line: sequence.sequence)
        }
        
        Console.writeToStdOut("Written sequences to \(dataWriter.url.path).")
    }
}



