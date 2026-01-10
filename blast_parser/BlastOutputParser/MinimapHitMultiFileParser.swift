//
//  MinimapMultiClassificationFileParser.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

final class MinimapHitMultiFileParser {
    var databases = [MinimapDatabase]()
    var mainBins = [MinimapHitBin]()
    var mergedHits = [MinimapMergedHit]()
    
    private var _prefixes = [String]()
    var prefixes: [String] {
        guard _prefixes.isEmpty == false else { return _prefixes }
        _prefixes = databases.map(\.prefix)
        return _prefixes
    }
    
    var mainDatabase:MinimapDatabase? {
        return self.databases.mainDatabase
    }
    
    var mainHitPrefix:String? {
        return self.databases.mainDatabase?.prefix
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
        let database = try MinimapDatabase(path: mainDirectory, isMain: true)
        databases.append(database)
        
        if let directories = representativeDirectories {
            let directoryPaths = directories.components(separatedBy: " ")
            
            for directory in directoryPaths {
                // check if they are valid directories and then saved them
                let database = try MinimapDatabase(path: directory)
                databases.append(database)
            }
        }
    }
    
    /// Merges different hit files, which should contain the exact same assignments,
    /// classified by using minimap2 with different databases
    /// - Returns: An array of MinimapMergedHit objects that contain the merged columns
    /// containing the taxonomy and the score of the assignment
    func merge() throws {
        try consolidateHits()
        try mergeHits()
    }
    
    // MARK: Private methods
    private func consolidateHits() throws {
        let mainHits = databases.mainHits
        mainBins.appendBins(from: mainHits)
    }
    
    private func mergeHits() throws {
        let queryIDs = databases.representativeQueryIDs
        
        for queryID in queryIDs {
            guard mainBins.isHitUnique(queryID: queryID) else {
                throw RuntimeError("Found multiple minimap2 hits for the same query ID: \(queryID).")
            }
            
            guard let bin = mainBins.bin(for: queryID) else {
                throw RuntimeError("No bin was found for query ID: \(queryID)")
            }
            
            
            
        }
    }
}
