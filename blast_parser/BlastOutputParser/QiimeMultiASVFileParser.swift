//
//  QiimeMultiASVFileParser.swift
//  blast_parser
//
//  Created by João Varela on 14/07/2025.
//

import Foundation

fileprivate struct QiimeASVFile {
    let path: String
    var asvs:[QiimeASV]
    let headerPrefix: String
    
    /// QiimeASVFile parses the column headers with a prefix
    /// - Parameter path: path to the file containing the taxonomy and
    /// the assignment confidence value for each ASV
    /// - Parameter asvs: array of the taxonomy and confidence for each ASV
    /// - Parameter prefix:prefix to add to the header column names
    init(path: String, asvs: [QiimeASV], prefix: String) {
        self.path = path
        self.asvs = asvs
        
        if prefix.isEmpty == false {
            self.headerPrefix = prefix
        } else {
            // The default prefix will be the directory name two levels up.
            // If the directory does not exit, no prefix will be added.
            let url = URL(fileURLWithPath: path, isDirectory: false)
            let dirURL = url.deletingLastPathComponent().deletingLastPathComponent()
            self.headerPrefix = dirURL.lastPathComponent
        }
    }
    
    /// Parses the header with the prefix given by the user to distinguish columns
    /// containing the taxonomy and the confidence values processed by Qiime using
    /// different databases
    mutating func parseHeader() throws {
        guard headerPrefix.isEmpty == false else { return }
        let header = asvs.first?.description
        guard let header = header
            else { throw RuntimeError("Parsing of a Qiime file header failed: " + "No valid header was found to be parsed.") }
        let headers = header.components(separatedBy: "\t")
        let taxonPrefixedHeaders = headers.map
            { $0.replacingOccurrences(of: "Taxon",
                                      with: "\(headerPrefix)-Taxon") }
        let confidencePrefixedHeaders = taxonPrefixedHeaders.map
            { $0.replacingOccurrences(of: "Confidence",
                                      with: "\(headerPrefix)-Confidence") }
       
        let prefixedHeaders = confidencePrefixedHeaders.map { String($0) }
        let taxonIndex = prefixedHeaders.firstIndex(of: "\(headerPrefix)-Taxon")
        guard let prefixedHeader = QiimeASV(components: prefixedHeaders,
                                            taxonIndex: taxonIndex) else {
            throw RuntimeError("Parsing of a Qiime file header failed: " + "Unable to find a taxon header")
        }
        asvs.removeFirst()
        asvs.insert(prefixedHeader, at: 0)
    }
}

final class QiimeMultiASVFileParser {
    var parsers: [QiimeParser]
    var prefixes: [String]
    
    /// QiimeMultiASVFileParser merges different ASV files by keeping an
    /// QiimeParser array, which will do the parsing of each ASV file
    /// - Parameter paths: paths separated by spaces to each ASV file
    /// - Parameter prefixes: prefixes to add to the header column names,
    /// following the order of the paths given, suitable to distinguish the
    /// output of Qiime2 using different databases
    init?(paths: String, prefixes:String?) {
        let pathsArray = paths.components(separatedBy: " ")
        self.parsers = pathsArray.compactMap { path in QiimeParser(path: path) }
        guard parsers.count == pathsArray.count else { return nil }
        
        if let prefixes = prefixes {
            self.prefixes = prefixes.components(separatedBy: " ").map { String($0) }
        } else {
            self.prefixes = []
        }
    }
    
    /// Merges different ASV files, which should contain the exact same assignments,
    /// classified by using Qiime2 with different databases
    /// - Returns: An array of QiimeASV objects that contain the merged columns containing
    /// the taxonomy and the confidence value of the assignment
    func merge() throws -> [QiimeASV] {
        var files = [QiimeASVFile]()
        
        // parse
        let prefixCount = prefixes.count
        for (i, parser) in parsers.enumerated() {
            let asvs = try parser.parse()
            let prefix = i < prefixCount ? prefixes[i] : ""
            var file = QiimeASVFile(path: parser.path, asvs: asvs, prefix: prefix)
            try file.parseHeader()
            files.append(file)
        }
        
        guard files.isEmpty == false else {
            throw RuntimeError("Merging of Qiime files failed: no files found.")
        }
        
        // check if the files can be merged
        let count = files[0].asvs.count
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
