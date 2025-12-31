//
//  MinimapFileParser.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

class MinimapFileParser: FileParser {
    var hits = [MinimapHit]()
        
    /// Parses a minimap2 classification file contqining a header with the following columns:
    /// Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy
    /// WARNING: Assumes the file is already sorted by Query_ID, Alignment_Score and
    /// Alignment_Length in descending order of the last two criteria
    func parse() throws {
        var index = 0
        var lastQueryID: String = ""
        
        for line in readStream {
            if index == 0 {
                // validation
                Console.writeToStdOut("Parsing minimap2 classification file: \(readStream.url.lastPathComponent)")
                
                let header = line.split(separator: "\t")
                guard header.count == 5 else {
                    throw RuntimeError("Invalid header line for minimap2 classification file")
                }
                guard header.contains("Query_ID"), header.contains("Reference_ID"),  header.contains("Alignment_Score"), header.contains("Alignment_Length"), header.contains("Taxonomy") else {
                    throw RuntimeError("Invalid header: It should contain the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy")
                }
                index += 1
            } else if index > 0 {
                do {
                    let hit = try MinimapHit(from: line)
                    
                    // retrieve only the best hit
                    if lastQueryID.isEmpty || lastQueryID != hit.queryID {
                        hits.append(hit)
                        lastQueryID = hit.queryID
                    }
                }
                
                catch {
                    // ignore any malformed hit and continue
                }
            }
        }
    }
}
