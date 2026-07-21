//
//  KrakenSequenceParser.swift
//  blast_parser
//
//  Created by João Varela on 01/11/2024.
//

import Foundation

final class KrakenSequence {
    let sequenceID:String
    var sequence:String
    
    init(sequenceID: String, sequence: String = String()) {
        self.sequenceID = sequenceID
        self.sequence = sequence
    }
}

final class KrakenSequenceParser: FileParser {
    var sequences = [KrakenSequence]()
    var separator = ">"
    
    override init?(path:String) {
        let fileExtension = URL(fileURLWithPath: path).pathExtension
        switch fileExtension {
        case "fastq":
            separator = "@"
        default:
            return nil
        }
        super.init(path: path)
    }
    
    /// Method to retrieve the sequences with the IDs present in the KrakenASV array
    func parse(asvs:[KrakenASV]) {
        getSequenceIDs(asvs: asvs)
        var sequenceID = String()
        let count = sequences.count
        var sequenceCount = 0
        var matchedID = false
        
        for line in readStream {
            if line.first == Character(separator) {
                sequenceID = line.replacingOccurrences(of: separator, with: "")
                sequenceID = sequenceID.components(separatedBy: " ").first!
                sequenceID = sequenceID.trimmingCharacters(in: .whitespacesAndNewlines)
                matchedID = true
            } else if matchedID {
                if let sequenceObj = match(sequenceID: sequenceID) {
                    sequenceObj.sequence = line.trimmingCharacters(in: .newlines)
                    sequenceCount += 1
                    if sequenceCount == count {
                        break
                    }
                }
                matchedID = false
            }
        }
    }
    
    /// Method needed to preserve the order of the ASVs
    private func getSequenceIDs(asvs:[KrakenASV]) {
        for asv in asvs {
            sequences.append(KrakenSequence(sequenceID: asv.sequenceID))
        }
    }
    
    private func match(sequenceID:String) -> KrakenSequence? {
        for sequence in sequences {
            if sequence.sequenceID == sequenceID {
                if sequence.sequence.isEmpty {
                    return sequence
                } else {
                    return nil
                }
            }
        }
        return nil
    }
}
