//
//  MinimapMergedHit.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

fileprivate struct MinimapSampleCounts: CustomStringConvertible {
    let sampleID:String
    let count:Int
    
    var description: String {
        return String(count)
    }
}

fileprivate extension [MinimapSampleCounts] {
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
    private var hits = [MinimapHit]()
    private var hitCounts = [MinimapSampleCounts]()
    
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
    
    func add(_ hit: MinimapHit) {
        hits.append(hit)
    }
    
    func appendCounts(from bin: MinimapHitBin) {
        
    }
}
