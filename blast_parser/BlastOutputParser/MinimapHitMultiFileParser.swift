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
    var parsers = [MinimapFileParser]()
    var databases = [MinimapDatabase]()
    var mergedHits = [MinimapMergedHit]()
    
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
            
            self.parsers = allPaths.compactMap { path in MinimapFileParser(path: path) }
            let database = MinimapDatabase(path: directory, isMain: isMainDirectory)
            databases.append(database)
        }
    }
    
    /// Merges different hit files, which should contain the exact same assignments,
    /// classified by using minimap2 with different databases
    /// - Returns: An array of MinimapMergedHit objects that contain the merged columns
    /// containing the taxonomy and the score of the assignment
    func merge() throws {
        try validateDatabases()
        try parseHitFiles()
        try parseRepresentativeHits()
    }
    
    /// Parse all hit files
    private func parseHitFiles() throws {
        for parser in parsers {
            try parser.parse()
        }
    }
    
    private func parseMainHits() throws {
        for parser in parsers {
            for hit in parser.hits {
                if hit.isMainFileHit {
                    
                }
            }
        }
    }
    
    private func parseRepresentativeHits() throws {
        for parser in parsers {
            for hit in parser.hits {
                if !hit.isMainFileHit {
                    
                }
            }
        }
    }
    
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
