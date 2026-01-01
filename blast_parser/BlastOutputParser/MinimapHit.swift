//
//  MinimapHit.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

/// Class for storing a minimap2 hit
final class MinimapHit: CustomStringConvertible {
    let queryID: String
    let referenceID: String
    let alignmentScore: Int
    let alignmentLength: Int
    let taxonomy: String
    private var _species: String? = nil
    
    var sampleID:String?
    
    var score:Int {
        (10000*alignmentScore + alignmentLength)/1000
    }
    
    var description: String {
        "\(queryID)\t\(referenceID)\t\(alignmentScore)\t\(alignmentLength)\t\(taxonomy)"
    }
    
    var abstract:String {
        "\(taxonomy)\t\(score)\t"
    }
    
    var species: String {
        if _species == nil {
            _species = taxonomy.split(separator: ";").last.map(String.init) ?? "Unassigned"
            
            // remove any strain information
            let components = _species!.split(separator: " ")
            if components.count > 2 {
                _species = String(components[0]) + " " + String(components[1])
            }
        }
        
        return _species ?? "Unassigned"
    }
    
    init(from line: String) throws {
        let components = line.split(separator: "\t").map(String.init)
        guard components.count == 5,
              let alignmentScore = Int(components[2]),
              let alignmentLength = Int(components[3]) else {
            throw RuntimeError("Invalid Minimap hit: \(line)")
        }
        
        self.queryID = components[0]
        self.referenceID = components[1]
        self.alignmentScore = alignmentScore
        self.alignmentLength = alignmentLength
        self.taxonomy = components[4]
    }
}

extension MinimapHit: Equatable {
    static func == (lhs: MinimapHit, rhs: MinimapHit) -> Bool {
        lhs.queryID == rhs.queryID
    }
}
