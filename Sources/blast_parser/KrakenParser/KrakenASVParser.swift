//
//  KrakenASVParser.swift
//  blast_parser
//
//  Created by João Varela on 27/10/2024.
//

import Foundation

final class KrakenASVParser: FileParser {
    var binArray = KrakenASVBinArray()
    
    func parse(format:ASVFormat = .standard) throws {
        var i = 1
        for line in readStream {
            let asv = try KrakenASV(line: line, format: format)
            binArray.append(asv: asv)
            i += 1
        }
        binArray.sort()
    }
}

