//
//  MinimapMultiClassificationFileParser.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

struct MinimapDatabase {
    let directoryPath: String
    let isMainDatabase: Bool
    let prefix: String
    
    init(path: String, isMain:Bool = false) throws {
        self.directoryPath = path
        guard let isDirectory = path.isDirectory, isDirectory else {
            throw RuntimeError("\(path) is not a directory or does not exist")
        }
        self.isMainDatabase = isMain
        self.prefix = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }
}

final class MinimapHitMultiFileParser {
    var databases = [MinimapDatabase]()
    var hits = [MinimapHit]()
    var mainBins = [MinimapHitBin]()
    var mergedHits = [MinimapMergedHit]()
    
    private var _prefixes = [String]()
    var prefixes: [String] {
        guard _prefixes.isEmpty == false else { return _prefixes }
        _prefixes = databases.map(\.prefix)
        return _prefixes
    }
    
    var mainHitPrefix:String? {
        return self.hits.first(where: {$0.isMainFileHit})?.prefix
    }
    
    var mainHits:[MinimapHit] {
        return self.hits.filter({$0.isMainFileHit})
    }
    
    var representativeHits:[MinimapHit] {
        return self.hits.filter({$0.isMainFileHit == false})
    }
    
    var sampleIDs:[String] {
        let samples: [String] = self.hits.map({$0.sampleID!})
        return Array(Set(samples))
            .sorted {$0.localizedStandardCompare($1) == .orderedAscending}
    }
    
    /// MinimapHitMultiFileParser merges different minimap2 hit files
    /// - Parameters:
    ///  - mainDirectory: path to the directory containing the main hit files with
    ///  all the reads assigned to their corresponding taxonomies; files must be named
    ///  as follows: 'sample_ID_classified.tsv'
    ///  - representativeDirectories: paths separated by spaces pointing to directories
    ///  containing the hits selected by the `parse-minimap` subcommand; files must be
    ///  named as follows: 'sample_ID_representative_classified.tsv'
    /// Prefixes corresponding to the databases used to classify the reads to be added
    /// to the header column names will be extracted from the directory name.
    init(mainDirectory:String, representativeDirectories:String?) throws {
        guard let mainPaths = mainDirectory.findFiles(suffix: .main) else {
            throw RuntimeError("No minimap2 hit files were found in \(mainDirectory)")
        }
        
        let database = try MinimapDatabase(path: mainDirectory, isMain: true)
        databases.append(database)
        let mainParsers = mainPaths.compactMap{ path in MinimapFileParser(path: path) }
        try parseHitFiles(parsers: mainParsers)
        
        if let directories = representativeDirectories {
            let directoryPaths = directories.components(separatedBy: " ")
            
            for directory in directoryPaths {
                // check if they are valid directories and then saved them
                let database = try MinimapDatabase(path: directory)
                databases.append(database)
                
                guard let paths = directory.findFiles(suffix: .representative) else {
                    throw RuntimeError("No minimap2 hit files were found in \(directory)")
                }
                
                let parsers = paths.compactMap { path in MinimapFileParser(path: path) }
                try parseHitFiles(parsers: parsers)
            }
        }
    }
    
    func hits(for prefix: String) -> [MinimapHit] {
        self.hits.filter({$0.prefix == prefix})
    }
    
    func hits(for prefix: String, sampleID: String) -> [MinimapHit] {
        self.hits.filter({$0.prefix == prefix && $0.sampleID == sampleID})
    }
    
    /// Merges different hit files, which should contain the exact same assignments,
    /// classified by using minimap2 with different databases
    /// - Returns: An array of MinimapMergedHit objects that contain the merged columns
    /// containing the taxonomy and the score of the assignment
    func merge() throws {
        try consolidateHits()
    }
    
    // MARK: Private methods
    private func consolidateHits() throws {
        guard let mainPrefix = mainHitPrefix else {
            throw RuntimeError("Unable to merge minimap hits, as a prefix for the main hits was not found.")
        }
        
        let mainHits = self.mainHits
        mainBins.appendBins(from: mainHits)
    }
    
    /// Parses hit files and appends them to the `hits` array of this object
    /// This peivate method is called by init.
    /// - Parameter parsers: parsers used to parse the hits in files, normally
    /// in a given directory
    private func parseHitFiles(parsers:[MinimapFileParser]) throws {
        // parse files
        for parser in parsers {
            try parser.parse()
            hits.append(contentsOf: parser.hits)
        }
    }
}
