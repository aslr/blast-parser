//
//  MinimapMergedHit.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

struct MinimapSampleCounts: CustomStringConvertible {
    let sampleID:String
    var count:Int
    
    var description: String {
        return String(count)
    }
    
    init(sampleID: String, count: Int = 0) {
        self.sampleID = sampleID
        self.count = count
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
    
    mutating func add(counts: [MinimapSampleCounts]) {
        for count in counts {
            self.add(sampleID: count.sampleID, count: count.count)
        }
    }
    
    mutating func add(sampleID: String, count: Int) {
        if let index = self.firstIndex(where: { $0.sampleID == sampleID }) {
            self[index].count += count  // Direct mutation
        } else {
            self.append(MinimapSampleCounts(sampleID: sampleID, count: count))
        }
    }
}

/// Class for storing and merging one or more minimap2 hits
/// classified using different databases but referring to
/// the same read
final class MinimapMergedHit: CustomStringConvertible {
    let prefixes: [String]
    let queryID: String
    let binID: UUID
    var hits = [MinimapHit]()
    var hitCounts = [MinimapSampleCounts]()
    var averageScore = 0
    
    var coreDescription: String {
        "\(hits.map(\.abstract).joined(separator: "\t"))\t\(averageScore)"
    }
    
    var description: String {
        "\(queryID)\t\(coreDescription)"
    }
    
    var abstract: String {
        "\(coreDescription)\t\(hitCounts.countsDescription)"
    }
    
    var coreHeader: String? {
        var result = ""
        guard hits.count == prefixes.count else { return nil }
        for prefix in prefixes {
            result += "\(prefix)_Taxonomy\t\(prefix)_Score\t"
        }
        result += "Average_Score"
        return result
    }
    
    var header:String? {
        guard let coreHeader = self.coreHeader else { return nil }
        return "Query_ID\t\(coreHeader)"
    }
    
    var abstractHeader: String? {
        guard let coreHeader = self.coreHeader else { return nil }
        return coreHeader + "\t\(hitCounts.sampleIDDescription)"
    }
    
    var taxonomy: String {
        "\(hits.map(\.taxonomy).joined(separator: "\t"))"
    }
    
    /// Initializer for a class used to store a minimap2 hit for a
    /// given read and merge the taxonomic assignment obtained from
    /// different databases
    /// - Parameters:
    ///  - prefixes: prefixes to add to the column headers
    ///  - queryID: the read id
    ///  - hit: first hit to be merged
    ///  - binID: bin UUID of each main hit to allow the proper merging of
    ///  hits coming from the same bin
    init(prefixes:[String], queryID: String, hit: MinimapHit, binID:UUID) {
        self.prefixes = prefixes
        self.queryID = queryID
        self.hits.append(hit)
        self.binID = binID
    }
    
    func add(_ hit: MinimapHit) {
        hits.append(hit)
    }
    
    func appendCounts(from bin: MinimapHitBin, sampleIDs: [String]) {
        for sampleID in sampleIDs {
            let counts = bin.hits(sampleID: sampleID).count
            let storage = MinimapSampleCounts(sampleID: sampleID, count: counts)
            hitCounts.append(storage)
        }
    }
    
    /// Sets the average score from the main hits bin
    /// This means that this NOT the average score across different databases
    /// or classifiers but only the average score for all hits using the main
    /// classifier
    /// - Parameter bin - the bin containing all (main) hits
    func setAverageScore(from bin: MinimapHitBin) {
        averageScore = bin.averageScore
    }
}
