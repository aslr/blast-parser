//
//  MinimapParser.swift
//  blast_parser
//
//  Created by João Varela on 27/12/2025.
//

import Foundation

final class MinimapParser: FileParser {
    let readsPath: String
    let hitsPerBin: Int
    var hits = [MinimapHit]()
    var bins = [MinimapHitBin]()
    var sequences = [FastqSequence]()
    var fastqOutputPath: String?
    var fastaOutputPath: String?
    var statsOutputPath: String?
    
    init?(path: String, readsPath:String, hitsPerBin:Int = 5) {
        self.readsPath = readsPath
        self.hitsPerBin = hitsPerBin
        super.init(path: path)
    }
    
    /// Parses a minimap2 classification file contqining a header with the following columns:
    /// Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy
    /// WARNING: Assumes the file is already sorted by Query_ID, Alignment_Score and
    /// Alignment_Length in descending order of the last two criteria
    func parse() throws {
        var index = 0
        var lastQueryID: String = ""
        
        for line in readStream {
            if index == 0 {
                // validation
                Console.writeToStdOut("Parsing minimap2 classification file: \(readStream.url.lastPathComponent)\n")
                
                let header = line.split(separator: "\t")
                guard header.count == 5 else {
                    throw RuntimeError("Invalid header line for minimap2 classification file")
                }
                guard header.contains("Query_ID"), header.contains("Reference_ID"),  header.contains("Alignment_Score"), header.contains("Alignment_Length"), header.contains("Taxonomy") else {
                    throw RuntimeError("Invalid header: It should contain the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy")
                }
                index += 1
            } else if index > 0 {
                do {
                    let hit = try MinimapHit(from: line)
                    
                    // retrieve only the best hit
                    if lastQueryID.isEmpty || lastQueryID != hit.queryID {
                        hits.append(hit)
                        lastQueryID = hit.queryID
                    }
                }
                
                catch {
                    // ignore any malformed hit and continue
                }
            }
        }
        
        parseBins()
        try parseSequences()
    }
    
    func print() throws {
        Console.writeToStdOut("Generating output files...")
        
        guard fastqOutputPath != nil || fastaOutputPath != nil || statsOutputPath != nil else {
            throw RuntimeError("ERROR: No output file was specified")
        }
        
        if let path = fastqOutputPath {
            guard let writer = FileWriter(path: path) else {
                throw RuntimeError("Unable to write to file at \(path) due to a malformed path.")
            }
            let fastqWriter = try writer.makeDataWriter()
            
            for sequence in sequences {
                fastqWriter.write(line: sequence.description)
            }
            
            Console.writeToStdOut("Generated output .fastq file \(fastqWriter.url.lastPathComponent) with representative sequences.")
        }
        
        if let path = fastaOutputPath {
            guard let writer = FileWriter(path: path) else {
                throw RuntimeError("Unable to write to file at \(path) due to a malformed path.")
            }
            let fastaWriter = try writer.makeDataWriter()
            
            for sequence in sequences {
                fastaWriter.write(line: sequence.fasta)
            }
            
            Console.writeToStdOut("Generated output .fasta file \(fastaWriter.url.lastPathComponent) with representative sequences.")
        }
        
        if let path = statsOutputPath {
            guard let writer = FileWriter(path: path) else {
                throw RuntimeError("Unable to write to file at \(path) due to a malformed path.")
            }
            let statsWriter = try writer.makeDataWriter()
            
            for bin in bins {
                statsWriter.write(line: bin.description)
            }
            
            Console.writeToStdOut("Generated stats file \(statsWriter.url.lastPathComponent).")
        }
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
        Console.writeToStdOut("Making sequence bins with the same taxonomic assignment...")
        
        for hit in hits {
            if let bin = matchBin(keyword: hit.species) {
                bin.add(hit)
            } else {
                let bin = MinimapHitBin()
                bin.add(hit)
                bins.append(bin)
            }
        }
    }
    
    private func parseSequences() throws {
        Console.writeToStdOut("Parsing reads file for selected minimap2 hits...")
        let hits = self.selectedHits()
        
        guard let fastqParser = FastqParser(path: readsPath) else {
            throw RuntimeError("Failed to parse .fastq file as a valid reads file could not be found at \(path)")
        }
    
        try fastqParser.parse()
        
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
            _selectedHits.append(contentsOf: bin.hits(maximumHits: hitsPerBin))
        }
        return _selectedHits
    }
}
