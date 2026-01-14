//
//  BlastMinimapOutputParser.swift
//  blast_parser
//
//  Created by João Varela on 30/12/2025.
//

import Foundation

final class BlastMinimapOutputParser: BlastOutputParser {
    let multiFileParser: MinimapHitMultiFileParser
    var outputMergedFile:String?
    var outputHitCountsFile:String?
    
    /// Parser for outputing the results of merging BLASTn hits
    /// - Parameters:
    ///  - path: path to the BLAST hits file
    ///  - mainHits: path to the directory to find minimap2 main hit
    ///  files containing the taxonomic assignment of all reads
    ///  - representativeHits: space-separated paths to the directories
    ///  to find minimap2 representative hits containing the taxonomic
    ///  assignment of reads selected by the `parse-minimap` subcommand.
    init?(path:String, mainHits:String, representativeHits:String?) {
        do {
            multiFileParser = try MinimapHitMultiFileParser(mainDirectory: mainHits,
                                                            representativeDirectories: representativeHits)
            super.init(path: path)
        }
        
        catch {
            return nil
        }
    }
    
    override func merge() throws {
        Console.writeToStdOut("Merging minimap2 hits with BLASTn output...")
        
        guard hits.isEmpty == false && bins.isEmpty == false else {
            throw RuntimeError("Unable to merge BLAST hits with the minimap2 table because no BLAST hits or bins were found.")
        }
        
        try multiFileParser.merge()
        let mergedHits = multiFileParser.mergedHits
        
        guard mergedHits.isEmpty == false else {
            throw RuntimeError("Unable to merge BLAST hits with minimap hit table because no BLAST hits were found.")
        }
        
        let taxonomyDatabase = SQLDatabase(database: taxonomyDatabase,
                                           table: taxonomyTable)
        taxonomyDatabase.connect()
        
        for bin in bins {
            
            
        }
    }
    
    func print() throws {
        let mergedFilePath = resolveOutputMergedFilePath()
        try printMergedFile(path: mergedFilePath)
        
        let hitCountsFilePath = resolveOutputHitCountsFilePath()
        try printHitCountsFile(path: hitCountsFilePath)
    }
    
    // MARK: Private
    private func blastFilename() -> String {
        URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }
    
    private func printHitCountsFile(path: String) throws {
        
    }
    
    private func printMergedFile(path: String) throws {
        guard let writer = FileWriter(path:path) else {
            throw RuntimeError("Unable to print merged minimap2 and BLASTn hits to file due to a malformed path.")
        }
        let dataWriter = try writer.makeDataWriter()
        
        let mergedHits = multiFileParser.mergedHits
        for mergedHit in mergedHits {
            dataWriter.write(line: mergedHit.description)
        }
    }
    
    private func resolveOutputMergedFilePath() -> String {
        if let outputMergedFile = self.outputMergedFile,
           outputMergedFile.resolvedFileURL() != nil {
            return outputMergedFile
        } else {
            return "\(blastFilename())_merged_output.tsv"
        }
    }
    
    private func resolveOutputHitCountsFilePath() -> String {
        if let outputHitCountsFile = self.outputHitCountsFile,
           outputHitCountsFile.resolvedFileURL() != nil {
            return outputHitCountsFile
        } else {
            return "\(blastFilename())_hitcounts_output.tsv"
        }
    }
}
