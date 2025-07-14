//
//  QiimeMultiASVFileParser.swift
//  blast_parser
//
//  Created by João Varela on 14/07/2025.
//

import Foundation

struct QiimeASVFile {
    let path: String
    let asvs:[QiimeASV]
    let headerPrefix: String
}

final class QiimeMultiASVFileParser {
    var parsers = [QiimeParser]()
    
    init?(paths: String) {
        let pathsArray = paths.components(separatedBy: " ")
        self.parsers = pathsArray.compactMap { path in QiimeParser(path: path) }
        guard parsers.count == pathsArray.count else { return nil }
    }
    
    func parse() throws -> [QiimeASV] {
        
    }
}
