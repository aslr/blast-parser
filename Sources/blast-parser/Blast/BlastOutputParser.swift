//
//  BlastOutputParser.swift
//  blast_parser
//
//  Created by João Varela on 13/07/2025.
//

import ArgumentParser

class BlastOutputParser: FileParser {
	var hits = [BlastHit]()
	var bins = [BlastHitBin]()
	var hitsPerASV = 1
    
    func parse(lineageDBPath:String,
               criterion:BlastHit.SortCriterion = .bitScore) throws {
        try parseBlastOutput()
        try parseBins(criterion: criterion)
        try merge(lineageDB: lineageDBPath)
    }
    
    /// Placeholder for a merging hits method
    /// Default implementation does nothing
    func merge(lineageDB path:String) throws {}
    
    private func parseBlastOutput() throws {
        Console.writeToStdOut("Parsing BLASTn output at \(path)")
        
        for line in readStream {
            let hit = try BlastHit(line: line)
            hits.append(hit)
        }
    }
    
    /// Parses the BLASTn output into bins with the same sequenceID
    /// Assumes the hits are sorted by their sequenceIDs
    private func parseBins(criterion:BlastHit.SortCriterion) throws {
        Console.writeToStdOut("Parsing BLASTn output into bins...")
        var previousID = String()
        for hit in hits {
            if hit.querySequenceID != previousID {
                let bin = BlastHitBin(hit: hit)
                bin.sort(criterion: criterion)
                bins.append(bin)
                previousID = hit.querySequenceID
            } else {
                if let previousBin = bins.last {
                    previousBin.append(hit: hit)
                } else {
                    throw ValidationError("Unable to append BLAST hit to bin.")
                }
            }
        }
    }
}
