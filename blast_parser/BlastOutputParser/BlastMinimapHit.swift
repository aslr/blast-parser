//
//  BlastMinimapHit.swift
//  blast_parser
//
//  Created by João Varela on 12/01/2026.
//

import Foundation

final class BlastMinimapHit: BlastASV {
    let minimapHit: MinimapMergedHit
    
    init(minimapHit: MinimapMergedHit, hit: BlastHit) {
        self.minimapHit = minimapHit
        super.init(hit: hit)
    }
    
    override var description: String {
        "\(minimapHit)\t\(super.description)"
    }
    
    var abstract: String {
        "\(minimapHit.abstract)\t\(super.description)"
    }
    
    override var header: String? {
        guard let minimapHeader = minimapHit.header else { return nil }
        return "\(minimapHeader)\t\(super.header!)"
    }
    
    var abstractHeader: String? {
        guard let minimapAbstract = minimapHit.abstractHeader else { return nil }
        return "\(minimapAbstract)\t\(super.header!)"
    }
}
