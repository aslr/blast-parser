//
//  MinimapHitBin.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

/// Class used to create and store main hit bins
/// CAUTION: Do NOT use it with representative hits as the latter lack any information
/// about hit counts
final class MinimapHitBin: CustomStringConvertible {
    let id = UUID()
    private var hits = [MinimapHit]()
    var maximumScore = 0
    var minimumScore = 0
    
    var hitCount: Int {
        hits.count
    }
    
    var queryIDs: [String] {
        hits.map(\.queryID)
    }
    
    var taxonomy: String {
        hits.first?.taxonomy ?? "No taxonomy was found"
    }
    
    var taxon: String? {
        hits.first?.taxon
    }
    
    var description: String {
        return "\(taxonomy)\t\(hits.count)\t\(maximumScore)\t\(minimumScore)"
    }
    
    func add(_ hit: MinimapHit) {
        hits.append(hit)
        
        if hit.score > maximumScore {
            maximumScore = hit.score
            if minimumScore == 0 {
                minimumScore = hit.score
            }
        }
        if hit.score < minimumScore {
            minimumScore = hit.score
        }
    }
    
    func containsHit(queryID:String) -> Bool {
        hits.contains(where: { $0.queryID == queryID })
    }
    
    func hit(queryID:String) -> MinimapHit? {
        return hits.first(where: { $0.queryID == queryID })
    }
    
    /// Retrieves a minimap2 hit with a given score or lower
    /// - Parameter score: score of the hit calculated from the minimap2 alignment score and length
    /// - Returns: a minimap hit with an approximate given score if one exists
    func hit(score:Int) -> MinimapHit? {
        hits.first(where: { $0.score <= score })
    }
    
    func hits(queryID: String) -> [MinimapHit] {
        hits.filter { $0.queryID == queryID }
    }
    
    func hits(sampleID: String) -> [MinimapHit] {
        hits.filter { $0.sampleID == sampleID }
    }
    
    /// Retrieve hits with different scores
    /// This can be used to verify the validity of the minimap scores
    /// - Parameter maximumHits: Maximum umber of hits to retrieve from the bin
    /// - Returns: a minimap hit array within its full range of scores
    func hits(maximumHits:Int) -> [MinimapHit] {
        var selectedHits = [MinimapHit]()
        
        if hitCount <= maximumHits {
            selectedHits = hits
        } else {
            let scoreStep = (maximumScore - minimumScore) / maximumHits
            var score = maximumScore
            while score > minimumScore, selectedHits.count < maximumHits {
                if let hit = hit(score: score) {
                    if !selectedHits.contains(where: { $0 == hit }) {
                        selectedHits.append(hit)
                    }
                }
                score -= scoreStep
            }
        }
        
        return selectedHits
    }
}

extension [MinimapHitBin] {
    /// Creates a new bin if the hit taxonomy is different, if the same
    /// appends the hit to the corresponding bin
    /// CAUTION: Do not use it with representative hits
    /// - Parameter hits - the hits to be added to the bin array
    mutating func appendBins(from hits: [MinimapHit]) {
        Console.writeToStdOut("Making sequence bins with the same taxonomic assignment...")
        
        for hit in hits {
            if let bin = self.first(where:{ $0.taxon == hit.taxon }) {
                bin.add(hit)
            } else {
                let bin = MinimapHitBin()
                bin.add(hit)
                self.append(bin)
            }
        }
    }
    
    func bin(for queryID: String) -> MinimapHitBin? {
        self.first(where: { $0.containsHit(queryID: queryID) })
    }
    
    /// Ensures the hit exits within the bin and is unique
    /// Used to validate the correctness of the bin array
    /// - Parameter queryID - the hit ID to find whether the hit is stored
    /// only once in the bin array
    /// - Returns: true if it exists and is not repeated within the bin
    func bins(for queryID: String) -> [MinimapHitBin] {
        self.filter( { $0.containsHit(queryID: queryID) })
    }
}
