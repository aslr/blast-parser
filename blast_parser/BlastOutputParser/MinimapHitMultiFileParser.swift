//
//  MinimapMultiClassificationFileParser.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

final class MinimapHitMultiFileParser {
    var parsers = [MinimapFileParser]()
    var prefixes = [String]()
    
    /// MinimapHitMultiFileParser merges different minimap2 hit files by keeping a
    /// QiimeParser array, which will do the parsing of each minimap2 hit file
    /// - Parameter paths: paths separated by spaces to each minimap2 hit file or paths pointing to directories containing such files; the path pointing
    /// to the main hits file containing all the reads must have the suffix
    /// '_classified.tsv'. Files containing only the hits selected by the
    /// parse-minimap subcommand must have the suffix '_representative_classified.tsv'
    /// The rest of the filename will be interpreted as the sample ID.
    /// Prefixes corresponding to the databases used to classify the reads to be added
    /// to the header column names will be extracted from the directory name
    init(paths:String) throws {
        let pathsArray = paths.components(separatedBy: " ")
        guard pathsArray.count > 0 else { throw RuntimeError("No valid minimap2 directories were provided. The path was empty.") }
        
        for directory in pathsArray {
            guard let isDirectory = directory.isDirectory, isDirectory else {throw RuntimeError("\(directory) is not a directory") }
            guard let mainPaths = directory.findFiles(suffix: "_classified.tsv")
                else { throw RuntimeError("No files ending in '_classified.tsv' were found in \(directory)") }
            guard let repPaths = directory.findFiles(suffix: "_representative_classified.tsv")
                else { throw RuntimeError("No files ending in '_representative_classified.tsv' were found in \(directory)") }
            let allPaths = mainPaths + repPaths
            self.parsers = allPaths.compactMap { path in MinimapFileParser(path: path) }
            let url = URL(fileURLWithPath: directory, isDirectory: true)
            let prefix = url.lastPathComponent
            prefixes.append(prefix)
        }
    }
    
    /// Merges different hit files, which should contain the exact same assignments,
    /// classified by using minimap2 with different databases
    /// - Returns: An array of MinimapMergedHit objects that contain the merged columns
    /// containing the taxonomy and the score of the assignment
    func merge() throws -> [MinimapMergedHit] {
        for parser in parsers {
            try parser.parse()
        }
        
        
    }
}
