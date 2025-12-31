//
//  BlastHitBin.swift
//  blast_parser
//
//  Created by João Varela on 03/11/2024.
//

import Foundation

class BlastHitBin {
    private var hits = [BlastHit]()
    
    var sequenceID:String? {
        guard hits.isEmpty == false else { return nil }
        return hits[0].querySequenceID
    }
    
    /// Retrieves the best BLASTn hits of a taxon
    /// Assumes that hits are already sorted
    /// using sort(criterion:)
    /// - Returns: the best hits per taxon
    var bestHitsPerTaxID:[BlastHit]? {
        var bestHits = [BlastHit]()
        var currentTaxID = -1
        for hit in hits {
            if hit.ncbiTaxID != currentTaxID {
                bestHits.append(hit)
                currentTaxID = hit.ncbiTaxID
            }
        }
        
        if bestHits.isEmpty {
            return nil
        } else {
            return bestHits
        }
    }
    
    init(hit:BlastHit) {
        hits.append(hit)
    }
    
    func append(hit:BlastHit) {
        hits.append(hit)
    }
    
    /// Retrieves the best BLASTn hits regardless of the taxon
    /// NOTE: assumes that hits are already sorted
    /// - Parameter hitNumber: number of hits to retrieve
    /// - Returns: the best hits
    func bestHits(_ hitNumber:Int = 1) -> [BlastHit]? {
        guard self.hits.isEmpty == false else { return nil }
        var hits = [BlastHit]()
        var i = 0
        for hit in self.hits {
            hits.append(hit)
            i += 1
            guard i < hitNumber else { break }
        }
        return hits
    }
    
    func sort(criterion:BlastHit.SortCriterion) {
        hits.sort(criterion: criterion)
    }
}
