//
//  MinimapDatabase.swift
//  blast_parser
//
//  Created by João Varela on 10/01/2026.
//

import Foundation

struct MinimapDatabase {
    let directoryPath: String
    let isMainDatabase: Bool
    let prefix: String
    var hits = [MinimapHit]()
    
    var sampleIDs:[String] {
        let samples: [String] = self.hits.map({$0.sampleID!})
        return Array(Set(samples))
            .sorted {$0.localizedStandardCompare($1) == .orderedAscending}
    }
    
    init(path: String, isMain:Bool = false) throws {
        self.directoryPath = path
        guard let isDirectory = path.isDirectory, isDirectory else {
            throw RuntimeError("\(path) is not a directory or does not exist")
        }
        self.isMainDatabase = isMain
        self.prefix = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        try parseHitFiles()
    }
    
    /// Parses hit files and appends them to the `hits` array of this object
    private mutating func parseHitFiles() throws {
        let suffix: MinimapFileSuffix = isMainDatabase ? .main : .representative
        
        guard let paths = directoryPath.findFiles(suffix: suffix) else {
            throw RuntimeError("No minimap2 hit files were found in \(directoryPath)")
        }
        
        let parsers = paths.compactMap{ path in MinimapFileParser(path: path) }
        
        for parser in parsers {
            try parser.parse()
            hits.append(contentsOf: parser.hits)
        }
    }
}

extension [MinimapDatabase] {
    var mainDatabase: MinimapDatabase? {
        return first(where: \.isMainDatabase)
    }
    
    var mainHits: [MinimapHit] {
        mainDatabase.map(\.hits) ?? []
    }
    
    var representativeHits: [MinimapHit] {
        self.filter({!$0.isMainDatabase}).flatMap(\.hits)
    }
    
    var isMainDatabaseUnique: Bool {
        self.map(\.isMainDatabase).count == 1
    }
    
    func hits(for prefix: String) -> [MinimapHit] {
        self.filter({$0.prefix == prefix}).flatMap(\.hits)
    }
    
    func hits(for prefix: String, sampleID: String) -> [MinimapHit] {
        self.filter({$0.prefix == prefix})
            .flatMap(\.hits)
            .filter({$0.sampleID == sampleID})
    }
}
