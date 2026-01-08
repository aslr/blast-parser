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
    
    init(path: String, isMain:Bool = false) {
        self.directoryPath = path
        guard let isDirectory = path.isDirectory, isDirectory else {
            fatalError("\(path) is not a directory or does not exist")
        }
        self.isMainDatabase = isMain
        self.prefix = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }
}

final class MinimapHitMultiFileParser {
    var databases = [MinimapDatabase]()
    var hits = [MinimapHit]()
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
    
    /// MinimapHitMultiFileParser merges different minimap2 hit files by keeping a
    /// QiimeParser array, which will do the parsing of each minimap2 hit file
    /// - Parameter paths: paths separated by spaces to each minimap2 hit file or paths
    /// pointing to directories containing such files; the path pointing
    /// to the main hits file containing all the reads must have the suffix
    /// '_classified.tsv'. Files containing only the hits selected by the
    /// parse-minimap subcommand must have the suffix '_representative_classified.tsv'
    /// The rest of the filename will be interpreted as the sample ID.
    /// Prefixes corresponding to the databases used to classify the reads to be added
    /// to the header column names will be extracted from the directory name
    init(paths:String) throws {
        let pathsArray = paths.components(separatedBy: " ")
        guard pathsArray.count > 0
        else {
            throw RuntimeError("No valid minimap2 directories were provided. The path was empty.")
        }
        
        var isMainDirectory = false
        for directory in pathsArray {
            guard let isDirectory = directory.isDirectory, isDirectory
                else { throw RuntimeError("\(directory) is not a directory") }
            
            var allPaths = [String]()
            if let mainPaths = directory.findFiles(suffix: .main) {
                allPaths = mainPaths
                isMainDirectory = true
            } else if let repPaths = directory.findFiles(suffix: .representative) {
                allPaths += repPaths
            }
            
            guard allPaths.isEmpty == false
                else { throw RuntimeError("No minimap2 hit files were found in \(directory)") }
            
            let parsers = allPaths.compactMap { path in MinimapFileParser(path: path) }
            try parseHitFiles(parsers: parsers)
            let database = MinimapDatabase(path: directory, isMain: isMainDirectory)
            databases.append(database)
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
        try validateDatabases()
        try consolidateHits()
    }
    
    // MARK: Private methods
    private func consolidateHits() throws {
        guard let mainPrefix = mainHitPrefix else {
            throw RuntimeError("Unable to merge minimap hits, as a prefix for the main hits was not found.")
        }
        
        let hits = mainHits
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
    
    /// Validates whether the expected main database was included, as this one has
    /// retained all reads, which will be essential to determine the hit counts for
    /// a particular taxon
    private func validateDatabases() throws {
        var mainDatabaseCount = 0
        for database in databases {
            if database.isMainDatabase {
                mainDatabaseCount += 1
            }
        }
        
        switch mainDatabaseCount {
        case 0:
            throw RuntimeError("ERROR: No directory was found containing main hit files, i.e., files containing the classification of all reads. This is not supported as hit counts cannot be determined without them.")
        case 1:
            return
        default:
            throw RuntimeError("ERROR: Only one directory may contains main hit files, i.e., files containing the classification of all reads. You can have multiple directories containing minimap2 hit files with representaive reads selected by the parse-minimap submcommand but you must have only one directory containing main hit files.")
        }
    }
}
