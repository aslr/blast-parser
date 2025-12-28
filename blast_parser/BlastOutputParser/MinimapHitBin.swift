//
//  MinimapHitBin.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

struct MinimapHitBin: CustomStringConvertible {
    private var hits = [MinimapHit]()
    var maximumScore = 0
    var minimumScore = 0
    
    var count: Int {
        hits.count
    }
    
    var taxonomy: String {
        hits.first?.taxonomy ?? "No taxonomy was found"
    }
    
    var species: String? {
        hits.first?.species
    }
    
    var description: String {
        return "\(taxonomy)\t\(hits.count)"
    }
    
    mutating func add(_ hit: MinimapHit) {
        hits.append(hit)
        
        if hit.score > maximumScore {
            maximumScore = hit.score
        }
        if hit.score < minimumScore {
            minimumScore = hit.score
        }
    }
    
    /// Retrieves a minimap2 hit with a given score or lower
    /// - Parameter score: score of the hit calculated from the minimap2 alignment score and length
    /// - Returns: a minimap hit with an approximate given score if one exists
    func hit(score:Int) -> MinimapHit? {
        hits.first(where: { $0.score <= score })
    }
    
    /// Retrieve hits with different scores
    /// This can be used to verify the validity of the minimap scores
    /// - Parameter numberToRetrieve: Number of hits to retrieve from the bin
    /// - Returns: a minimap hit array within its full range of scores
    func hits(numberToRetrieve:Int) -> [MinimapHit] {
        var selectedHits = [MinimapHit]()
        
        if count <= numberToRetrieve {
            selectedHits = hits
        } else {
            let scoreStep = (maximumScore - minimumScore) / numberToRetrieve
            var score = maximumScore
            while score > minimumScore, selectedHits.count < numberToRetrieve {
                if let hit = hit(score: score) {
                    if !hits.contains(where: { $0 == hit }) {
                        selectedHits.append(hit)
                    }
                }
                score -= scoreStep
            }
        }
        
        return selectedHits
    }
}
