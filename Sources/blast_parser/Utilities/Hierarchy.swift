//
//  KrakenHierarchy.swift
//  blast_parser
//
//  Created by João Varela on 22/09/2024.
//

import Foundation

struct Hierarchy: CustomStringConvertible {
    private var ranks = [KrakenRank]()
    
    var firstRank:KrakenRank? {
        return ranks.first
    }
    
    var lastRank:KrakenRank? {
        return ranks.last
    }
    
    var lastRankIndex:Int {
        return ranks.count - 1
    }
    
    var description: String {
        var rankString = String()
        
        for rank in ranks {
            if rank.variant == 0 {
                rankString += "\(rank.abbreviation):\(rank.taxonName);"
            }
        }
        
        return rankString
    }
    
    /// Default initializer with an Unclassified rank
    init() {
        if let rank = KrakenRank(rawValue: 0) {
            ranks.append(rank)
        }
    }
    
    /// Initializer with a NCBI lineage
    /// - parameters:
    ///   - lineage: NCBI taxonomic lineage obtained from the
    ///    PostgresSQL database obtained by the `import` and `export`
    ///    subcommands.
    init(lineage:TaxonRecord) throws {
        let domain = try KrakenRank.rank(abbreviation: "D",
                                         name: lineage.superkingdom)
        ranks.append(domain)
        
        let kingdom = try KrakenRank.rank(abbreviation: "K",
                                          name: lineage.kingdom)
        ranks.append(kingdom)
        
        let phylum = try KrakenRank.rank(abbreviation: "P",
                                         name: lineage.phylum)
        ranks.append(phylum)
        
        let `class` = try KrakenRank.rank(abbreviation: "C",
                                          name: lineage.class)
        ranks.append(`class`)
        
        let order = try KrakenRank.rank(abbreviation: "O",
                                        name: lineage.order)
        ranks.append(order)
        
        let family = try KrakenRank.rank(abbreviation: "F",
                                         name: lineage.family)
        ranks.append(family)
        
        let genus = try KrakenRank.rank(abbreviation: "G",
                                        name: lineage.genus)
        ranks.append(genus)
        
        let species = try KrakenRank.rank(abbreviation: "S",
                                          name: lineage.species)
        ranks.append(species)
    }
    
    /// Initializer with a parsed string
    /// - parameters:
    ///   - lineageString: string containing a lineage as parsed by `init(lineage:)`
    init(lineageString:String) throws {
        let components = lineageString.split(separator: ";")
        for component in components {
            let rankComponents = component.split(separator: ":")
            if rankComponents.count == 2 {
                let rank = try KrakenRank.rank(abbreviation: String(rankComponents[0]),
                                         name: String(rankComponents[1]))
                ranks.append(rank)
            } else {
                ranks.append(KrakenRank.unclassified())
                break
            }
        }
    }
    
    mutating func addRank(_ rank:KrakenRank) {
        ranks.append(rank)
    }
    
    mutating func dropLastRank() {
        ranks = ranks.dropLast(1)
    }
    
    mutating func equalizeWithParent(of rank:KrakenRank) {
        ranks.removeAll { $0 < rank || $0 == rank }
    }
    
    func getRank(index:Int) -> KrakenRank? {
        if index >= 0 && index < ranks.count {
            return ranks[index]
        }
        return nil
    }
    
    mutating func reset() {
        self.ranks = [KrakenRank]()
    }
}
