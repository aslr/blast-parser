//
//  MinimapMergedHit.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

/// Class for storing and merging one or more minimap2 hits
/// classified using different databases but referring to
/// the same read
final class MinimapMergedHit: CustomStringConvertible {
    var prefixes:[String]
    let queryID:String
    var hits:[MinimapHit]
    var hitCounts = 0
    
    var description: String {
        var result = "\(queryID)"
        for hit in hits {
            result += "\(hit.abstract)\t"
        }
        result += "\(hitCounts)"
        return result
    }
    
    var header:String {
        var result = "Query_ID"
        let addPrefixes = hits.count == prefixes.count
        for (i, _) in hits.enumerated() {
            if addPrefixes {
                result += "\(prefixes[i])_Taxonomy\t\(prefixes[i])_Score\t"
            } else {
                result += "Taxonomy\tScore\t"
            }
        }
        result += "Hit_Count"
        return result
    }
    
    /// Initializer for a class used to store a minimap2 hit for a
    /// given read and merge the taxonomic assignment obtained from
    /// different databases
    /// - Parameter prefixes: an array of prefixes to add to the column headers
    /// - Parameter qyeryID: the read id
    /// - Parameter hits: an array of hits to be merged
    init(prefixes:[String], queryID: String, hits: [MinimapHit]) {
        self.prefixes = prefixes
        self.queryID = queryID
        self.hits = hits
    }
}
