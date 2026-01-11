//
//  BlastMinimapOutputParser.swift
//  blast_parser
//
//  Created by João Varela on 30/12/2025.
//

import Foundation

final class BlastMinimapOutputParser: BlastOutputParser {
    let multiFileParser: MinimapHitMultiFileParser
    var outputMergedFile:String?
    var outputHitCountsFile:String?
    
    /// Parser for outputing the results of merging BLASTn hits
    /// - Parameters:
    ///  - path: path to the BLAST hits file
    ///  - mainHits: path to the directory to find minimap2 main hit
    ///  files containing the taxonomic assignment of all reads
    ///  - representativeHits: space-separated paths to the directories
    ///  to find minimap2 representative hits containing the taxonomic
    ///  assignment of reads selected by the `parse-minimap` subcommand.
    init?(path:String, mainHits:String, representativeHits:String?) {
        do {
            multiFileParser = try MinimapHitMultiFileParser(mainDirectory: mainHits,
                                                            representativeDirectories: representativeHits)
            super.init(path: path)
        }
        
        catch {
            return nil
        }
    }
    
    override func merge() throws {
        try multiFileParser.merge()
    }
    
    func print() throws {
        
    }
}
