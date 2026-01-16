//
//  BlastMinimapMultiFileParser.swift
//  blast_parser
//
//  Created by João Varela on 15/01/2026.
//

import Foundation

final class BlastMinimapOutputParser: BlastOutputParser {
    override func merge() throws {
        // do nothing as the merge will take place in the caller
        // but we need to overide this method in order to prevent
        // a fatal error in the base class
    }
}

class BlastMinimapMultiFileParser {
    var parsers = [BlastMinimapOutputParser]()
    
    var hits: [BlastHit] {
        parsers.map(\.hits).flatMap(\.self)
    }
    
    var bins: [BlastHitBin] {
        parsers.map(\.bins).flatMap(\.self)
    }
    
    init(path: String) throws {
        guard let paths = path.findFiles(suffix: .blast) else {
            throw RuntimeError("No files with suffix \(FileSuffix.blast.rawValue) were found in \(path).")
        }
        
        for path in paths {
            guard let parser = BlastMinimapOutputParser(path: path) else {
                throw RuntimeError("Unable to create BlastOutputParser for \(path).")
            }
            self.parsers.append(parser)
        }
    }
    
    func parse(criterion:BlastHit.SortCriterion = .bitScore) throws {
        for parser in parsers {
            try parser.parse(criterion: criterion)
        }
    }
}
