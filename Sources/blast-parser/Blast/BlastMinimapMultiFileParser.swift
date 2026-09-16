//
//  BlastMinimapMultiFileParser.swift
//  blast_parser
//
//  Created by João Varela on 15/01/2026.
//

import Foundation
import ArgumentParser

class BlastMinimapMultiFileParser {
    var parsers = [BlastOutputParser]()
    
    var hits: [BlastHit] {
        parsers.map(\.hits).flatMap(\.self)
    }
    
    var bins: [BlastHitBin] {
        parsers.map(\.bins).flatMap(\.self)
    }
    
    init(path: String) throws {
        guard let paths = path.findFiles(suffix: .blast) else {
            throw ValidationError("No files with suffix \(FileSuffix.blast.rawValue) were found in \(path).")
        }
        
        for path in paths {
            guard let parser = BlastOutputParser(path: path) else {
                throw ValidationError("Unable to create BlastOutputParser for \(path).")
            }
            self.parsers.append(parser)
        }
    }
    
    func parse(lineageDBPath:String, criterion:BlastHit.SortCriterion = .bitScore) throws {
        for parser in parsers {
            try parser.parse(lineageDBPath: lineageDBPath,
                             criterion: criterion)
        }
    }
}
