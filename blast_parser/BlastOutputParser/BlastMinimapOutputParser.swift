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
    
    init?(path:String, mainHits:String, representativeHits:String?) {
        do {
            self.multiFileParser = try MinimapHitMultiFileParser(mainDirectory: mainHits,
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
}
