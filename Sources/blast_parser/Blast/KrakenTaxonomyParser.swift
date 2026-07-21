//
//  KrakenTaxonomyParser.swift
//  blast_parser
//
//  Created by João Varela on 16/11/2024.
//

import Foundation

struct KrakenTaxonomyLine {
    let assignedReads: Int
    let name: String
    let taxID: Int
    let taxonomy: String
}

final class KrakenTaxonomyParser: FileParser {
    var lines = [KrakenTaxonomyLine]()
    /// Parses the output file of the parse subcommand (KrakenParser object) to retrieve
    /// the hierarchical taxonomic classification produced by Kraken2 with the following
    /// format: lineNumber percentage reads assignedReads rank.abbreviation rank-variant rank-name taxID lineage
    func parse() throws {
        for line in readStream {
            let items = line.components(separatedBy: "\t")
            guard items.count == 9 else {
                throw RuntimeError("Invalid Kraken taxonomy file")
            }
            
            let reads = Int(items[3].trimmingCharacters(in: .whitespaces)) ?? 0
            let name = items[6].trimmingCharacters(in: .whitespaces)
            let taxID = Int(items[7].trimmingCharacters(in: .whitespaces)) ?? 0
            let taxonomy = items[8].trimmingCharacters(in: .whitespacesAndNewlines)
            let taxonomyLine = KrakenTaxonomyLine(assignedReads: reads,
                                                  name: name,
                                                  taxID: taxID,
                                                  taxonomy: taxonomy)
            lines.append(taxonomyLine)
        }
    }
    
    func getTaxonomy(for asv:KrakenASV) -> String? {
        for line in lines {
            if asv.taxonomy.taxID == line.taxID {
                return line.taxonomy
            }
        }
        return nil
    }
}
