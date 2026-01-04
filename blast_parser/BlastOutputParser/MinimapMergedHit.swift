//
//  MinimapMergedHit.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

struct MinimapSampleCounts: CustomStringConvertible {
    let sampleID:String
    let count:Int
    
    var description: String {
        return String(count)
    }
}

extension [MinimapSampleCounts] {
    var sampleIDDescription: String {
        let idStrings: [String] = self.map(\.sampleID)
        return idStrings.joined(separator: "\t")
    }
    
    var countsDescription: String {
        let countStrings: [String] = self.map(\.description)
        return countStrings.joined(separator: "\t")
    }
}

/// Class for storing and merging one or more minimap2 hits
/// classified using different databases but referring to
/// the same read
final class MinimapMergedHit: CustomStringConvertible {
    var prefixes = [String]()
    let queryID:String
    var hits = [MinimapHit]()
    var hitCounts = [MinimapSampleCounts]()
    
    var description: String {
        var result = "\(queryID)"
        for hit in hits {
            result += "\(hit.abstract)\t"
        }
        result += "\(hitCounts.countsDescription)"
        return result
    }
    
    var header:String? {
        var result = "Query_ID"
        guard hits.count == prefixes.count else { return nil }
        for prefix in prefixes {
            result += "\(prefix)_Taxonomy\t\(prefix)_Score\t"
        }
        result += "\(hitCounts.sampleIDDescription)"
        return result
    }
    
    var mainHitPrefix:String? {
        return self.hits.first(where: {$0.isMainFileHit})?.prefix
    }
    
    var mainHits:[MinimapHit] {
        return self.hits.filter({$0.isMainFileHit})
    }
    
    var representativeHits:[MinimapHit] {
        return self.hits.filter({$0.isMainFileHit == false})
    }
    
    var sampleIDs:[String] {
        let samples: [String] = self.hits.map({$0.sampleID!})
        return Array(Set(samples))
            .sorted {$0.localizedStandardCompare($1) == .orderedAscending}
    }
    
    /// Initializer for a class used to store a minimap2 hit for a
    /// given read and merge the taxonomic assignment obtained from
    /// different databases
    /// - Parameter prefixes: prefixes to add to the column headers
    /// - Parameter queryID: the read id
    /// - Parameter hit: first hit to be merged
    init(prefixes:[String], queryID: String, hit: MinimapHit) {
        self.prefixes = prefixes
        self.queryID = queryID
        self.hits.append(hit)
    }
    
    func consolidateHits() throws {
        guard let mainPrefix = mainHitPrefix else {
            throw RuntimeError("Unable to merge minimap hits, as a prefix for the main hits was not found.")
        }
        
        let hits = representativeHits
    }
    
    func hits(for prefix: String) -> [MinimapHit] {
        self.hits.filter({$0.prefix == prefix})
    }
    
    func hits(for prefix: String, sampleID: String) -> [MinimapHit] {
        self.hits.filter({$0.prefix == prefix && $0.sampleID == sampleID})
    }
}
