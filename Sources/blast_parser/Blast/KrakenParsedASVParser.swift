//
//  KrakenParsedASVParser.swift
//  blast_parser
//
//  Created by João Varela on 16/11/2024.
//

import Foundation

final class KrakenParsedASVParser: FileParser {
    /// Parses the output file of the parsed subcommand containing
    /// the sequenceIDs and their respective Kraken2 classifications
    func parse() throws -> [KrakenASV] {
        var lines = [KrakenASV]()
        for line in readStream {
            let asv = try KrakenASV(line: line, format: .parsed)
            lines.append(asv)
        }
        return lines
    }
}
