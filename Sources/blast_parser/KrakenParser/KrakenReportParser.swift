//
//  KrakenReportParser.swift
//  blast_parser
//
//  Created by João Varela on 15/09/2024.
//

import Foundation

enum ReportParserError: Error {
    case invalidRank(line: Int, taxon:String)
}

final class KrakenReportParser: FileParser {
    var lines = [KrakenReportLine]()
    var hierarchy = Hierarchy()
    
    /// Main method to parse a Kraken2 report
    func parse() throws {
        var i = 1
        for line in readStream {
            let items = line.components(separatedBy: "\t")
            guard items.count == 6 else
                { throw RuntimeError("Invalid Kraken2 report.") }
            var reportLine = KrakenReportLine()
            reportLine.lineNumber = i
            let percentageString = items[0].trimmingCharacters(in: .whitespaces)
            reportLine.percentage = Double(percentageString) ?? 0.0
            reportLine.reads = Int(items[1]) ?? 0
            reportLine.assignedReads = Int(items[2]) ?? 0
            reportLine.taxID = Int(items[4]) ?? 0
            let taxonName = items[5].trimmingCharacters(in: .whitespaces)
            reportLine.rank = try parseRank(lineNumber: i,
                                            taxID: reportLine.taxID,
                                            abbreviation: items[3],
                                            name: taxonName)
            try parseHierarchy(lineNumber: i, rank: reportLine.rank)
            reportLine.hierarchy = hierarchy
            lines.append(reportLine)
            i += 1
        }
    }
    
    /// Sort the taxa by decreasing assigned counts
    func sort() {
        lines.sort(by: >)
    }
    
    /// Parses a line and its abbreviation
    /// - Parameters:
    ///     - line: the line being parsed of the Kraken2 report
    ///     - abbreviation: the abbreviation of the rank (e.g., "U" for "Unclassified")
    /// - Returns: A Rank object describing the taxonomic rank and name
    private func parseRank(lineNumber:Int,
                           taxID:Int,
                           abbreviation:String,
                           name:String) throws -> Rank  {
        // default rank is "U" or "Unclassified"
        switch abbreviation {
        case "U":
            return Rank.unclassified()
        case "R":
            return Rank.root()
        case "D":
            return Rank.domain(taxID: taxID,
                               name: name,
                               hierarchy: hierarchy)
        default:
            do {
                return try Rank.rank(abbreviation: abbreviation,
                                     name: name)
            }
            
            catch {
                throw ReportParserError.invalidRank(line: lineNumber,
                                                    taxon: name)
            }
        }
    }
    
    /// Parses a line to update the rank Hierarchy object
    /// - Parameters:
    ///     - line: the line being parsed of the Kraken2 report
    ///     - rank: the rank to be added to the Hierarchy object
    private func parseHierarchy(lineNumber:Int,
                                rank:Rank) throws {
        switch rank.abbreviation {
        case "U":
            break
        case "R":
            hierarchy.reset()
            hierarchy.addRank(rank)
        default:
            guard let previous = hierarchy.lastRank else {
                throw ReportParserError.invalidRank(line: lineNumber,
                                                    taxon: rank.taxonName)
            }
            
            if previous > rank {
                hierarchy.addRank(rank)
            } else if previous == rank {
                hierarchy.dropLastRank()
                hierarchy.addRank(rank)
            } else {
                hierarchy.equalizeWithParent(of: rank)
                hierarchy.addRank(rank)
            }
        }
    }
}

