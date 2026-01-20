//
//  MinimapFileParser.swift
//  blast_parser
//
//  Created by João Varela on 31/12/2025.
//

import Foundation

class MinimapFileParser: FileParser {
    var hits = [MinimapHit]()
    var bins = [MinimapHitBin]()
    
    var filename:String {
        readStream.url.lastPathComponent
    }
    
    /// Extracts the sampleID from the filename passed in path
    /// Assumes that it is either a main or a representative hit file
    /// whose filename has either '_representative_classified.tsv' or
    /// '_classified.tsv' as sufixes, respectively.
    private var _sampleID: String?
    var sampleID: String? {
        guard _sampleID == nil else { return _sampleID }
        // NOTE: the order of this test is important as .representative
        // contains .main, causing a parsing error if the order is reversed
        if let prefix = filename.sampleID(suffix: .representative) {
            _sampleID = prefix
            return prefix
        } else if let prefix = filename.sampleID(suffix: .main) {
            _sampleID = prefix
            return prefix
        }
        return nil
    }
    
    private var _isMainFile: Bool? = nil
    var isMainFile: Bool {
        guard _isMainFile == nil else { return _isMainFile! }
        _isMainFile = filename.hasSuffix(FileSuffix.main.rawValue)
        return _isMainFile!
    }
    
    var directory: String? {
        readStream.url.deletingLastPathComponent().lastPathComponent
    }
        
    /// Parses a minimap2 classification file containing a header with the following columns:
    /// Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy by retrieving the
    /// best hit for each read
    /// WARNING: Assumes the file is already sorted by Query_ID, Alignment_Score and
    /// Alignment_Length in descending order of the last two criteria
    func parse() throws {
        var index = 0
        var lastQueryID: String = ""
        
        for line in readStream {
            if index == 0 {
                // validation
                Console.writeToStdOut("Parsing minimap2 classification file: \(filename)")
                
                let header = line.split(separator: "\t")
                guard header.count == 5 else {
                    throw RuntimeError("Invalid header line for minimap2 classification file")
                }
                guard header.contains("Query_ID"), header.contains("Reference_ID"), header.contains("Alignment_Score"), header.contains("Alignment_Length"), header.contains("Taxonomy") else {
                    throw RuntimeError("Invalid header: It should contain the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy")
                }
                index += 1
            } else if index > 0 {
                do {
                    let hit = try MinimapHit(from: line)
                    
                    // retrieve only the best hit
                    if lastQueryID.isEmpty || lastQueryID != hit.queryID {
                        hit.sampleID = sampleID
                        hit.isMainFileHit = isMainFile
                        hit.prefix = directory
                        hits.append(hit)
                        lastQueryID = hit.queryID
                    }
                }
                
                catch {
                    // ignore any malformed hit and continue
                }
            }
        }
    }
}
