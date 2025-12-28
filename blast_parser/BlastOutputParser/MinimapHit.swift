//
//  MinimapHit.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

struct MinimapHit: CustomStringConvertible {
    let queryID: String
    let referenceID: String
    let alignmentScore: Int
    let alignmentLength: Int
    let taxonomy: String
    
    var score:Int {
        10000*alignmentScore + alignmentLength
    }
    
    var description: String {
        "\(queryID)\t\(referenceID)\t\(alignmentScore)\t\(alignmentLength)\t\(taxonomy)"
    }
    
    var species: String {
        taxonomy.split(separator: ";").last.map(String.init) ?? "Unassigned"
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
