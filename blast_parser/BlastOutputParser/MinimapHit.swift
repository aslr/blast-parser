//
//  MinimapHit.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

/// Class for storing a minimap2 hit
final class MinimapHit: CustomStringConvertible {
    let unassignedTaxon = "Unassigned"
    let queryID: String
    let referenceID: String
    let alignmentScore: Int
    let alignmentLength: Int
    let taxonomy: String
    var sampleID:String?
    var prefix:String?
    var isMainFileHit = false
    
    var score:Int {
        (10000*alignmentScore + alignmentLength)/1000
    }
    
    var description: String {
        "\(queryID)\t\(referenceID)\t\(alignmentScore)\t\(alignmentLength)\t\(taxonomy)"
    }
    
    var abstract:String {
        "\(taxonomy)\t\(score)\t"
    }
    
    private var _taxon: String? = nil
    var taxon: String {
        if _taxon == nil {
            _taxon = taxonomy.split(separator: ";").last.map(String.init) ?? unassignedTaxon
            
            // remove any strain information
            let components = _taxon!.split(separator: " ")
            if components.count > 2 {
                _taxon = String(components[0]) + " " + String(components[1])
            }
        }
        
        return _taxon ?? unassignedTaxon
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
