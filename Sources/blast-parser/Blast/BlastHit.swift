//
//  BlastHit.swift
//  blast_parser
//
//  Created by João Varela on 03/11/2024.
//

import Foundation
import ArgumentParser

struct BlastHit: CustomStringConvertible {
    enum SortCriterion:String {
        case identity = "pident"
        case eValue = "evalue"
        case bitScore = "bitscore"
    }
    
    let querySequenceID:String
    let subjectSequenceID:String
    let percentageIdentity:Double
    let alignmentLength:Int
    let bitscore:Int
    let eValue:Double
    let ncbiTaxID:Int
    let scientificName:String
    let kingdom:String
    
    var description:String {
        return """
                    \(subjectSequenceID)\t\
                    \(percentageIdentity)\t\
                    \(bitscore)\t\
                    \(eValue)\t\
                    \(ncbiTaxID)\t\
                    \(scientificName)
               """
    }
    
    var header: String {
        "Subject\tIdentity\tScore\tE_value\tTaxID\tScientific_Name"
    }
    
    /// Standard initializer
    init(querySequenceID:String = String(),
         subjectSequenceID:String,
         percentageIdentity:Double,
         alignmentLength:Int = 0,
         bitscore:Int,
         eValue:Double,
         ncbiTaxID:Int,
         scientificName:String,
         kingdom:String = String()) {
        self.querySequenceID = querySequenceID
        self.subjectSequenceID = subjectSequenceID
        self.percentageIdentity = percentageIdentity
        self.alignmentLength = alignmentLength
        self.bitscore = bitscore
        self.eValue = eValue
        self.ncbiTaxID = ncbiTaxID
        self.scientificName = scientificName
        self.kingdom = kingdom
    }
    
    /// Initializer to parse a 13-column BLASTn hit
    /// - parameters:
    ///   - line containing the following columns:
    /// A: qseqid = Query Seq-id (ID of your sequence)
    /// B: pident = Percentage of identical matches
    /// C: length = Alignment length
    /// D: evalue = Expected value (E-value)
    /// E: bitscore = Bit score
    /// F: score = Raw score
    /// G: nident = Number of identical matches
    /// H: saccver = Subject accession.version
    /// I: stitle = Subject Title
    /// J: qcovs = Query Coverage Per Subject
    /// K: staxids = unique Subject Taxonomy ID(s), separated by a ';' (in numerical order)
    /// L: sscinames = unique Subject Scientific Name(s), separated by a ';'
    /// M: sskingdoms = unique Subject Super Kingdom(s), separated by a ';' (in alphabetical order)
    init(line:String) throws {
        let items = line.components(separatedBy: "\t")
        guard items.count == 13 else
            { throw ValidationError("Invalid BLASTn output format.") }
        let qSeqID = items[0].trimmingCharacters(in: .whitespaces)
        let sSeqID = items[7].trimmingCharacters(in: .whitespaces)
        let pIdentity = Double(items[1].trimmingCharacters(in: .whitespaces)) ?? 0.0
        let length = Int(items[2].trimmingCharacters(in: .whitespaces)) ?? 0
        let eValue = Double(items[3].trimmingCharacters(in: .whitespaces)) ?? 0.0
        let bitscore = Int(items[4].trimmingCharacters(in: .whitespaces)) ?? 0
        let taxID = Int(items[10].trimmingCharacters(in: .whitespaces)) ?? 0
        let name = items[11].trimmingCharacters(in: .whitespaces)
        let kingdom = items[12].trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(querySequenceID: qSeqID,
                  subjectSequenceID: sSeqID,
                  percentageIdentity: pIdentity,
                  alignmentLength: length,
                  bitscore: bitscore,
                  eValue: eValue,
                  ncbiTaxID: taxID,
                  scientificName: name,
                  kingdom: kingdom)
    }
    
    /// Initializer for a parsed 6-column BlastHit
    /// - parameters:
    ///  - line containing the following columns:
    ///     subjectSequenceID:Int
    ///     percentageIdentity:Int
    ///     bitscore:Int
    ///     eValue:Double
    ///     ncbiTaxID:Int
    ///     scientificName:String
    init(parsedLine:String) throws {
        let items = parsedLine.split(separator: "\t")
        guard items.count == 6 else
            { throw ValidationError("Invalid BLASTn output format.") }
        self.init(subjectSequenceID: String(items[0]),
                  percentageIdentity: Double(items[1]) ?? 0.0,
                  bitscore: Int(items[2]) ?? 0,
                  eValue: Double(items[3]) ?? 0.0,
                  ncbiTaxID: Int(items[4]) ?? 0,
                  scientificName: String(items[5]))
    }
    
    /// Fallback to initialize an empty BlastHit object
    init() {
        self.init(subjectSequenceID: "",
                  percentageIdentity: 0.0,
                  bitscore: 0,
                  eValue: 0,
                  ncbiTaxID: 0,
                  scientificName: "Unclassified")
    }
}

extension BlastHit {
    static func sortByIdentity(_ lhs:BlastHit,_ rhs:BlastHit) -> Bool {
        lhs.percentageIdentity > rhs.percentageIdentity
    }
    
    static func sortByEValue(_ lhs:BlastHit,_ rhs:BlastHit) -> Bool {
        lhs.eValue < rhs.eValue
    }
    
    static func sortByBitScore(_ lhs:BlastHit,_ rhs:BlastHit) -> Bool {
        lhs.bitscore > rhs.bitscore
    }
}

extension [BlastHit] {
    mutating func sort(criterion:BlastHit.SortCriterion) {
        switch criterion {
        case .identity:
            self.sort(by: BlastHit.sortByIdentity)
        case .eValue:
            self.sort(by: BlastHit.sortByEValue)
        case .bitScore:
            self.sort(by: BlastHit.sortByBitScore)
        }
    }
}





