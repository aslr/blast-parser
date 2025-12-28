//
//  MinimapParser.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

final class MinimapParser: FileParser {
    var hits = [MinimapHit]()
    var bins = [MinimapHitBin()]
    
    func parse() throws {
        var index = 0
        
        for line in readStream {
            if index == 0 {
                // validation
                let header = line.split(separator: "\t")
                guard header.count == 5 else {
                    throw RuntimeError("Invalid header line for minimap2 classification file")
                }
                guard header.contains("Query_ID"), header.contains("Reference_ID"),  header.contains("Alignment_Score"), header.contains("Alignment_length"), header.contains("Taxonomy") else {
                    throw RuntimeError("Invalid header: It should contain the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_length, Taxonomy")
                }
                index += 1
            } else if index > 0 {
                let hit = try MinimapHit(from: line)
                hits.append(hit)
            }
        }
    }
    
    func makeBins() {
        
    }
}
