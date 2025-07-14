//
//  QiimeMultiASVFileParser.swift
//  blast_parser
//
//  Created by João Varela on 14/07/2025.
//

import Foundation

struct QiimeASVFile {
    let path: String
    var asvs:[QiimeASV]
    let headerPrefix: String
    
    init(path: String, asvs: [QiimeASV]) {
        self.path = path
        self.asvs = asvs
        let url = URL(fileURLWithPath: path, isDirectory: false)
        let dirURL = url.deletingLastPathComponent()
        // the default prefix will be the directory name
        self.headerPrefix = dirURL.lastPathComponent
    }
    
    mutating func parseHeader() throws {
        let header = asvs.first?.description
        guard let header = header
            else { throw RuntimeError("Parsing of a Qiime file header failed.") }
        let headers = header.components(separatedBy: "\t")
        let taxonPrefixedHeaders = headers.map
            { $0.replacingOccurrences(of: "Taxon",
                                      with: "\(headerPrefix)-Taxon") }
        let confidencePrefixedHeaders = taxonPrefixedHeaders.map
            { $0.replacingOccurrences(of: "Confidence",
                                      with: "\(headerPrefix)-Confidence") }
       
        let prefixedHeaders = confidencePrefixedHeaders.map { String($0) }
        let prefixedHeader = QiimeASV(components: prefixedHeaders)
        asvs.removeFirst()
        asvs.insert(prefixedHeader, at: 0)
    }
}

final class QiimeMultiASVFileParser {
    var parsers = [QiimeParser]()
    
    init?(paths: String) {
        let pathsArray = paths.components(separatedBy: " ")
        self.parsers = pathsArray.compactMap { path in QiimeParser(path: path) }
        guard parsers.count == pathsArray.count else { return nil }
    }
    
    func merge() throws -> [QiimeASV] {
        var files = [QiimeASVFile]()
        
        // parse
        for parser in parsers {
            let asvs = try parser.parse()
            var file = QiimeASVFile(path: parser.path, asvs: asvs)
            try file.parseHeader()
            files.append(file)
        }
        
        guard files.isEmpty == false else {
            throw RuntimeError("Merging of Qiime files failed: no files found.")
        }
        
        // check if the files can be merged
        var count = files[0].asvs.count
        for file in files[1...] {
            guard count == file.asvs.count else {
                throw RuntimeError("Merging of Qiime files failed: " +
                                   "files have different number of ASVs.")
            }
        }
        
        // merge
        var mergedASVs = files[0].asvs
        
        for file in files[1...] {
            for (i, asv) in file.asvs.enumerated() {
                guard mergedASVs[i].featureID == asv.featureID else {
                    throw RuntimeError("Merging of Qiime files failed: " +
                                       "ASV IDs do not match.")
                }
                
                mergedASVs[i].add(taxonomy: asv.taxonomy[0])
            }
        }
        
        return mergedASVs
    }
}
