//
//  MinimapHitBin.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

struct MinimapHitBin {
    private var hits = [MinimapHit]()
    var maximumScore = 0
    var minimumScore = 0
    
    var count: Int {
        hits.count
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
    
    func hit(score:Int) -> MinimapHit? {
        hits.first(where: { $0.score <= score })
    }
    
    /// Retrieve hits with different scores to determine the validity of the
    /// scores upon validation of each hit
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
