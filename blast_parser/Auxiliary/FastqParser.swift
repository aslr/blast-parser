//
//  FastqParser.swift
//  blast_parser
//
//  Created by João Varela on 28/12/2025.
//

struct FastqSequence: CustomStringConvertible {
    let id:String
    let sequence:String
    let quality:String
    
    var description: String {
        "\(id)\n\(sequence)\n+\n\(quality)"
    }
    
    var fasta: String {
        ">\(id)\n\(sequence)"
    }
}

final class FastqParser: FileParser {
    var sequences = [FastqSequence]()
    
    func sequence(queryID:String) -> FastqSequence? {
        for sequence in sequences {
            guard sequence.id == queryID else { continue }
            return sequence
        }
        return nil
    }
    
    func parse() throws {
        var sequenceID:String? = nil
        var sequence:String? = nil
        var quality:String? = nil
        var sequenceLength = 0
        
        for line in readStream {
            // remove empty lines
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard cleanLine != "" else { continue }
            
            if cleanLine.hasPrefix("@") {
                // retrieve only the queryID
                guard let readID = cleanLine.split(separator: " ").map(String.init).first else { throw RuntimeError("Invalid FastQ file at \(path)") }
                    sequenceID = readID
                    sequenceID!.removeFirst()
            } else if sequenceID != nil && sequence == nil && quality == nil {
                guard isValidNucleotideSequence(cleanLine) else { throw RuntimeError("Invalid sequence \(sequenceID!) in file at \(path)")
                }
                sequence = cleanLine
                sequenceLength = cleanLine.count
            } else if cleanLine == "+" {
                guard sequenceID != nil, sequence != nil, quality == nil else {
                    throw RuntimeError("Malformed in sequence: \(sequenceID!) in file at \(path)")
                }
                continue
            } else if sequenceID != nil && sequence != nil && quality == nil {
                guard isValidQualityString(cleanLine) else { throw RuntimeError("Invalid quality score in sequence \(sequenceID!) in file at \(path)")
                }
                quality = cleanLine
                guard cleanLine.count == sequenceLength else { throw RuntimeError("Quality string length does not match nucleotide sequence length in sequence \(sequenceID!) in file at \(path)")
                }
            } else if sequenceID != nil && sequence != nil && quality != nil {
                let fastqSequence = FastqSequence(id: sequenceID!, sequence: sequence!, quality: quality!)
                sequences.append(fastqSequence)
                sequenceID = nil
                sequence = nil
                quality = nil
                sequenceLength = 0
            } else {
                throw RuntimeError("Invalid FastQ file at \(path)")
            }
        }
    }
    
    /// Checks if a sequence contains only valid nucleotide codes
    /// - Parameter sequence: The nucleotide sequence to validate
    /// - Parameter allowAmbiguous: Whether to allow IUPAC ambiguity codes (default: true)
    /// - Returns: true if all characters are valid nucleotide codes
    func isValidNucleotideSequence(_ sequence: String, allowAmbiguous: Bool = true) -> Bool {
        let validCodes: Set<Character>
        
        if allowAmbiguous {
            // IUPAC nucleotide codes (including ambiguity codes)
            validCodes = Set("ACGTURYSWKMBDHVNacgturyswkmbdhvn")
        } else {
            // Standard nucleotides only
            validCodes = Set("ACGTUacgtu")
        }
        
        return sequence.allSatisfy { validCodes.contains($0) }
    }
    
    /// Checks if a quality string contains only valid quality characters
    /// Valid characters: ASCII 33-126 (!"#$%&'()*+,-./0-9:;<=>?@A-Z[\]^_`a-z{|}~)
    /// - Parameter quality: The quality string to validate
    /// - Returns: true if all characters are valid quality characters
    func isValidQualityString(_ quality: String) -> Bool {
        let validChars = Set("!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")
        return quality.allSatisfy { validChars.contains($0) }
    }
}
