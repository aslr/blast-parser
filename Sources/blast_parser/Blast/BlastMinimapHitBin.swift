//
//  BlastMinimapHitBin.swift
//  blast_parser
//
//  Created by João Varela on 17/01/2026.
//

import Foundation

final class BlastMinimapHitBin: CustomStringConvertible {
    var hits = [BlastMinimapHit]()
    var hitCounts = [MinimapSampleCounts]()
    var averageScore: Int {
        Int(hits.map(\.averageScore).reduce(0, +) / hits.count)
    }
    
    var binID:UUID? {
        sortedHits.first?.minimapHit.binID
    }
    
    var scientificName: String {
        sortedHits.first?.hit.scientificName ?? "Unassigned"
    }
    
    var bestHit: BlastMinimapHit? {
        sortedHits.first
    }
    
    var bestScore: Int {
        sortedHits.first?.averageScore ?? 0
    }
    
    var sortedHits: [BlastMinimapHit] {
        hits.sorted(by: { $0.averageScore > $1.averageScore })
    }
    
    var header: String? {
        return sortedHits.first?.abstractHeader
    }
    
    var description: String {
        let sortedHits = sortedHits
        guard sortedHits.isEmpty == false else { return "No hits" }
        return sortedHits.first!.abstract
    }
}


