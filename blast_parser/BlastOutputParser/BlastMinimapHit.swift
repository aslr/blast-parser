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
        "\(super.description)\t\(minimapHit.description)"
    }
    
    var abstract: String {
        "\(super.description)\t\(minimapHit.abstract)"
    }
    
    override var header: String? {
        guard let minimapHeader = minimapHit.header else { return nil }
        return "\(super.header!)\t\(minimapHeader)"
    }
    
    var abstractHeader: String? {
        guard let minimapAbstract = minimapHit.abstractHeader else { return nil }
        return "\(super.header!)\t\(minimapAbstract)"
    }
}
