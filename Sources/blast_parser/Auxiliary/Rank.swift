//
//  KrakenRank.swift
//  blast_parser
//
//  Created by João Varela on 17/09/2024.
//

import Foundation

enum RankError:Error {
    case invalid
    case invalidHierarchy
}

struct Rank: RawRepresentable {
    static let ranks = ["Unclassified",
                        "Root",
                        "Domain",
                        "Kingdom",
                        "Phylum",
                        "Class",
                        "Order",
                        "Family",
                        "Genus",
                        "Species"]
    static let abbreviations = ["U","R","D","K","P","C","O","F","G","S"]
    
    typealias RawValue = Int
    var rawValue:Int
    var variant = 0
    var abbreviation:String = ""
    var rank:String = ""
    var taxonName:String = ""
    
    
    /// - Parameter rawValue: a raw value representing a main taxonomic rank
    /// Pass a value between 0 and 9, where the latter is the species rank.
    /// See the `ranks` and `abbreviations` arrays to see what values you can use.
    /// Pass 0 to get a default "Unclassified" rank
    init?(rawValue:Int) {
        self.rawValue = rawValue
        guard rawValue >= 0 && rawValue <= 9 else { return nil }
        abbreviation = Rank.abbreviations[rawValue]
        rank = Rank.ranks[rawValue]
    }
    
    /// Initializer that uses an abbreviation to initialize a Rank object
    /// - Parameter rankCodeString: abbreviation obtained from a line of a Kraken2 report
    /// Pass one of the values in the `abbreviations` array into rank.
    /// This initializer also accepts abbreviations containing a number (e.g., D2).
    /// In the latter case, the abbreviation and the number are used to initialize
    /// the `abbreviation` and `variant` instance variables, respectively.
    init?(rankCodeString:String) {
        if rankCodeString.count == 1 {
            if let index = Rank.abbreviations.firstIndex(of: rankCodeString) {
                self.rawValue = index
                self.abbreviation = rankCodeString
                self.rank = Rank.ranks[index]
            } else {
                return nil
            }
        } else if rankCodeString.count == 2 {
            guard let first = rankCodeString.first else { return nil }
            let abbreviation = String(first)
            if let index = Rank.abbreviations.firstIndex(of: abbreviation) {
                self.rawValue = index
                self.abbreviation = abbreviation
                self.rank = Rank.ranks[index]
                guard let last = rankCodeString.last else { return nil }
                guard let variant = Int(String(last)) else { return nil }
                self.variant = variant
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: static methods
    /// It does not add an "Unclassified" rank to the Hierarchy.current because
    /// it assumes that the first line is always such a rank, which is the
    /// default when a Hierachy object is initialized
    /// - returns: An unclassified Rank object
    static func unclassified() -> Rank {
        var rank = Rank(rawValue: 0)!
        rank.taxonName = rank.rank
        return rank
    }
    
    /// Returns a root Rank object
    static func root() -> Rank {
        var rank = Rank(rawValue: 1)!
        rank.taxonName = rank.rank
        return rank
    }
    
    /// It handles an oddity in Kraken2 reports in that a given rank can be
    /// classified as "D" or "Domain" even though it is not one of the recognized
    /// three domains of cellular organisms, namely "Archaea", "Bacteria" and "Eukaryota"
    ///
    /// When an abbreviation with a number is passed in the ReportLine object,
    /// the `variant` instance variable is initialized. This variable can also be
    /// initialized when it parses a domain not recognized as one of the three possible
    /// domains as mentioned above.
    ///
    /// Known limitation: it does not handle non-celullar entities such as viruses
    /// - Returns: A domain Rank object
    static func domain(taxID:Int, name:String, hierarchy:Hierarchy) -> Rank {
        var rank = Rank(rawValue: 2)!
        switch taxID {
        // handle "true" domains as defined in Rank, assuming that the tax IDs are
        // 2 for "Archaea", 3 for "Bacteria" and 4 for "Eukaryota".
        case 2, 3, 4:
        // handle cases where Kraken2 classifies a taxon as "D"
        // without being a "true" domain adding a variant
            break
        default:
            var i = hierarchy.lastRankIndex
            var count = 0
            while i >= 0 {
                if let currentRank = hierarchy.getRank(index: i) {
                    if currentRank.rawValue == rank.rawValue {
                        count += 1
                    } else {
                        break
                    }
                }
                i -= 1
            }
            rank.variant = count
        }
        rank.taxonName = name
        return rank
    }
    
    /// - Returns: A general Rank object
    static func rank(abbreviation:String,
                     name:String) throws -> Rank {
        guard var rank = Rank(rankCodeString: abbreviation)
            else { throw RankError.invalid }
        rank.taxonName = name.isEmpty ? "Incertae Sedis" : name
        return rank
    }
}

extension Rank: Equatable {
    static func == (lhs:Rank, rhs:Rank) -> Bool {
        return lhs.rawValue == rhs.rawValue &&
                lhs.variant == rhs.variant
    }
    
    static func != (lhs:Rank, rhs:Rank) -> Bool {
        return lhs.rawValue != rhs.rawValue ||
                lhs.variant != rhs.variant
    }
}

extension Rank: Comparable {
    static func < (lhs:Rank, rhs:Rank) -> Bool {
        if lhs.rawValue > rhs.rawValue {
            return true
        } else if lhs.rawValue == rhs.rawValue {
            return lhs.variant > rhs.variant
        }
        return false
    }
    
    static func > (lhs:Rank, rhs:Rank) -> Bool {
        if lhs.rawValue < rhs.rawValue {
            return true
        } else if lhs.rawValue == rhs.rawValue {
            return lhs.variant < rhs.variant
        }
        return false
    }
}

