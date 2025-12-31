//
//  MinimapMultiClassificationFileParser.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

final class MinimapHitMultiFileParser {
    var parsers = [MinimapFileParser]()
    var prefixes:[String]
    
    /// MinimapHitMultiFileParser merges different minimap2 hit files by keeping a
    /// QiimeParser array, which will do the parsing of each minimap2 hit file
    /// - Parameter paths: paths separated by spaces to each minimap2 hit file, the first path
    /// muast be the main hits file containing all the reads; if a path to a directory is given,
    /// the file with the suffix '_classified.tsv' will be used as the main hits file. Files
    /// containing only the select hits should have the suffix '_representative_classified.tsv'.
    /// - Parameter prefixes: prefixes to add to the header column names,
    /// following the order of the paths given, suitable to distinguish the
    /// output of minimap2 using different databases
    init?(paths:String, prefixes:String) {
        let pathsArray = paths.components(separatedBy: " ")
        if pathsArray.count == 1 {
            // assume it is a directory if only one path was given
            if let isDirectory = pathsArray[0].isDirectory, isDirectory {
                let directory = pathsArray.first!
                // search for main file
                guard let mainPath = directory.findFiles(suffix: "_classified.tsv")
                    else { return nil }
                guard let repPaths = directory.findFiles(suffix: "_representative_classified.tsv")
                    else { return nil }
                let allPaths = mainPath + repPaths
                self.parsers = allPaths.compactMap { path in MinimapFileParser(path: path) }
            } else {
                // not merging with just one file
                return nil
            }
        } else if pathsArray.count > 1 {
            // assume that they are file paths
            self.parsers = pathsArray.compactMap { path in MinimapFileParser(path: path) }
        }
        
        self.prefixes = prefixes.components(separatedBy: " ").map { String($0) }
    }
    
    /// Merges different hit files, which should contain the exact same assignments,
    /// classified by using minimap2 with different databases
    /// - Returns: An array of MinimapMergedHit objects that contain the merged columns containing
    /// the taxonomy and the score of the assignment
    func merge() throws -> [MinimapMergedHit] {
        for parser in parsers {
            try parser.parse()
        }
        
        
    }
}
