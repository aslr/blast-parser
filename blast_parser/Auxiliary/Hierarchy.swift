//
//  KrakenHierarchy.swift
//  blast_parser
//
//  Created by João Varela on 22/09/2024.
//

import Foundation

struct Hierarchy: CustomStringConvertible {
    private var ranks = [Rank]()
    
    var firstRank:Rank? {
        return ranks.first
    }
    
    var lastRank:Rank? {
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
        if let rank = Rank(rawValue: 0) {
            ranks.append(rank)
        }
    }
    
    /// Initializer with a NCBI lineage
    /// - parameters:
    ///   - lineage: NCBI taxonomic lineage obtained from the
    ///    PostgresSQL database obtained by the `import` and `export`
    ///    subcommands.
    init(lineage:NCBILineage) throws {
        let domain = try Rank.rank(abbreviation: "D",
                                   name: lineage.superkingdom)
        ranks.append(domain)
        
        let kingdom = try Rank.rank(abbreviation: "K",
                                    name: lineage.kingdom)
        ranks.append(kingdom)
        
        let phylum = try Rank.rank(abbreviation: "P",
                                   name: lineage.phylum)
        ranks.append(phylum)
        
        let `class` = try Rank.rank(abbreviation: "C",
                                   name: lineage.class)
        ranks.append(`class`)
        
        let order = try Rank.rank(abbreviation: "O",
                                  name: lineage.order)
        ranks.append(order)
        
        let family = try Rank.rank(abbreviation: "F",
                                   name: lineage.family)
        ranks.append(family)
        
        let genus = try Rank.rank(abbreviation: "G",
                                  name: lineage.genus)
        ranks.append(genus)
        
        let species = try Rank.rank(abbreviation: "S",
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
                let rank = try Rank.rank(abbreviation: String(rankComponents[0]),
                                         name: String(rankComponents[1]))
                ranks.append(rank)
            } else {
                ranks.append(Rank.unclassified())
                break
            }
        }
    }
    
    mutating func addRank(_ rank:Rank) {
        ranks.append(rank)
    }
    
    mutating func dropLastRank() {
        ranks = ranks.dropLast(1)
    }
    
    mutating func equalizeWithParent(of rank:Rank) {
        ranks.removeAll { $0 < rank || $0 == rank }
    }
    
    func getRank(index:Int) -> Rank? {
        if index >= 0 && index < ranks.count {
            return ranks[index]
        }
        return nil
    }
    
    mutating func reset() {
        self.ranks = [Rank]()
    }
}
