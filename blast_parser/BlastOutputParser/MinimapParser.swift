//
//  MinimapParser.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

final class MinimapParser: FileParser {
    let sequencesPath: String
    let hitsPerBin: Int
    var hits = [MinimapHit]()
    var bins = [MinimapHitBin()]
    var sequences = [FastqSequence]()
    
    init?(path: String, sequencesPath:String, hitsPerBin:Int = 5) {
        self.sequencesPath = sequencesPath
        self.hitsPerBin = hitsPerBin
        super.init(path: path)
    }
    
    func parse() throws {
        var index = 0
        
        for line in readStream {
            if index == 0 {
                // validation
                let header = line.split(separator: "\t")
                guard header.count == 5 else {
                    throw RuntimeError("Invalid header line for minimap2 classification file")
                }
                guard header.contains("Query_ID"), header.contains("Reference_ID"),  header.contains("Alignment_Score"), header.contains("Alignment_length"), header.contains("Taxonomy") else {
                    throw RuntimeError("Invalid header: It should contain the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_length, Taxonomy")
                }
                index += 1
            } else if index > 0 {
                let hit = try MinimapHit(from: line)
                hits.append(hit)
            }
        }
        
        parseBins()
        try parseSequences()
    }
    
    // MARK: Private
    private func matchBin(keyword:String) -> MinimapHitBin? {
        for bin in bins {
            if bin.species == keyword {
                return bin
            }
        }
        return nil
    }
    
    private func parseBins() {
        for hit in hits {
            if var bin = matchBin(keyword: hit.species) {
                bin.add(hit)
            } else {
                var bin = MinimapHitBin()
                bin.add(hit)
            }
        }
    }
    
    private func parseSequences() throws {
        guard let fastqParser = FastqParser(path: sequencesPath) else {
            throw RuntimeError("Failed to parse fastq file as a valid file could not be found at \(path)")
        }
        let hits = self.selectedHits()
        
        for hit in hits {
            guard let sequence = fastqParser.sequence(queryID: hit.queryID) else {
                throw RuntimeError("Failed to retrieve sequence with ID \(hit.queryID) in file at \(path)")
            }
            sequences.append(sequence)
        }
    }
    
    private func selectedHits() -> [MinimapHit] {
        var _selectedHits = [MinimapHit]()
        for bin in bins {
            _selectedHits.append(contentsOf: bin.hits(numberToRetrieve: hitsPerBin))
        }
        return _selectedHits
    }
}
