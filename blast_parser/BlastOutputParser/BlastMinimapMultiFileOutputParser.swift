//
//  BlastMinimapMultiFileOutputParser.swift
//  blast_parser
//
//  Created by João Varela on 30/12/2025.
//

import Foundation

final class BlastMinimapMultiFileOutputParser: BlastMinimapMultiFileParser {
    let multiFileParser: MinimapHitMultiFileParser
    var mergedBlastHits = [BlastMinimapHit]()
    var mergedBlastHitBins = [BlastMinimapHitBin]()
    var outputMergedFile:String?
    var outputHitCountsFile:String?
    
    /// Parser for outputing the results of merging BLASTn hits
    /// - Parameters:
    ///  - path: path to the BLAST hits directory
    ///  - mainHits: path to the directory to find minimap2 main hit
    ///  files containing the taxonomic assignment of all reads
    ///  - representativeHits: space-separated paths to the directories
    ///  to find minimap2 representative hits containing the taxonomic
    ///  assignment of reads selected by the `parse-minimap` subcommand.
    init?(path:String, mainHits:String, representativeHits:String?) {
        do {
            multiFileParser = try MinimapHitMultiFileParser(mainDirectory: mainHits,
                                                            representativeDirectories: representativeHits)
            try super.init(path: path)
        }
        
        catch {
            return nil
        }
    }
    
    /// Merges minimap2 with BLASTn hits of each bin but taking into account
    /// their queryIDs to match them together; then bins them into bins with
    /// unique taxonomy assignments for calculating the correct hit counts
    /// per taxon
    /// Used in `merge-minimap` subcommand, where `hitsPerASV` is always 1
    func merge() throws {
        Console.writeToStdOut("Merging minimap2 hits with BLASTn output...")
        
        // make local variables as self vars are computed
        let hits = self.hits
        let bins = self.bins
        
        guard hits.isEmpty == false && bins.isEmpty == false else {
            throw RuntimeError("Unable to merge BLAST hits with the minimap2 table because no BLAST hits or bins were found.")
        }
        
        try multiFileParser.merge()
        let mergedHits = multiFileParser.mergedHits
        
        guard mergedHits.isEmpty == false else {
            throw RuntimeError("Unable to merge BLAST hits with minimap hit table because no BLAST hits were found.")
        }
        
        let taxonomyDatabase = SQLDatabase(database: .database,
                                           table: .table)
        taxonomyDatabase.connect()
        
        for mergedHit in mergedHits {
            if let bin = bins.bin(for: mergedHit.queryID),
               let bestHit = bin.bestHits()?.first {
                let blastMergedHit = BlastMinimapHit(minimapHit: mergedHit,
                                                     hit: bestHit)
                blastMergedHit.setBlastTaxonomy(database: taxonomyDatabase)
                mergedBlastHits.append(blastMergedHit)
            } else {
                // no BLAST hit was found for this minimap hit, so generate and
                // append an "Unclassified" BlastHit
                let blastMergedHit = BlastMinimapHit(minimapHit: mergedHit,
                                                  hit: BlastHit())
                mergedBlastHits.append(blastMergedHit)
            }
        }
        
        taxonomyDatabase.disconnect()
        
        Console.writeToStdOut("Merging hits into bins...")
        try mergeBins()
    }
    
    func print() throws {
        let mergedFilePath = resolveOutputMergedFilePath()
        try printMergedFile(path: mergedFilePath)
        
        let hitCountsFilePath = resolveOutputHitCountsFilePath()
        try printHitCountsFile(path: hitCountsFilePath)
        
        Console.writeToStdOut("Ended the merge-minimap subcommand successfully...")
    }
    
    /// Bins the merged blast hits into bins with unique taxonomy
    /// assignments for calculating the correct hit counts per taxon
    private func mergeBins() throws {
        var lastBin: BlastMinimapHitBin? = nil
        
        // merge first by binID which identifies the original bins obtained
        // via the main classifier
        mergedBlastHits.sort(by: { $0.minimapHit.binID > $1.minimapHit.binID })
        for mergedHit in mergedBlastHits {
            if mergedHit.minimapHit.binID != lastBin?.binID {
                let bin = BlastMinimapHitBin()
                bin.hits.append(mergedHit)
                bin.hitCounts = mergedHit.minimapHit.hitCounts
                mergedBlastHitBins.append(bin)
                lastBin = bin
            } else {
                lastBin?.hits.append(mergedHit)
            }
        }
        
        // re-merge according to the same NCBI scientific name
        lastBin = nil
        let sortedBins = mergedBlastHitBins.sorted(by: { $0.scientificName < $1.scientificName })
        for bin in sortedBins {
            if bin.binID != lastBin?.binID {
                let bin = BlastMinimapHitBin()
                bin.hits.append(contentsOf: bin.hits)
                if let counts = bin.bestHit?.minimapHit.hitCounts {
                    bin.hitCounts = counts
                }
                mergedBlastHitBins.append(bin)
                lastBin = bin
            } else {
                lastBin?.hits.append(contentsOf: bin.hits)
                lastBin?.hitCounts.add(counts: bin.hitCounts)
            }
        }
    }
    
    /// Print the hit counts of the merged output table
    /// This table results from the consolidation of all sequence bins
    /// into bins containing the same taxonomic assignment using the main
    /// classifier for the minimap hits (i.e., the "main hits") and the
    /// BLASTn assignment using the core_nt database
    /// - Parameter path: path for the output file to be written to
    private func printHitCountsFile(path: String) throws {
        Console.writeToStdOut("Writing \(path) output file...")
        
        guard let writer = FileWriter(path:path) else {
            throw RuntimeError("Unable to print the hits counts to file due to a malformed path.")
        }
        let dataWriter = try writer.makeDataWriter()
        
        guard let header = mergedBlastHitBins.first?.header else {
            throw RuntimeError("Unable to print the hits counts to file as no merged hits were found.")
        }
        dataWriter.write(line: header)
        
        for bin in mergedBlastHitBins {
            dataWriter.write(line: bin.description)
        }
    }
    
    /// Print the merged output table containing all selected hits,
    /// their assignments and their queryIDs
    /// - Parameter path: path for the output file to be written to
    private func printMergedFile(path: String) throws {
        Console.writeToStdOut("Writing \(path) hit counts file...")
        
        guard let writer = FileWriter(path:path) else {
            throw RuntimeError("Unable to print merged minimap2 and BLASTn hits to file due to a malformed path.")
        }
        let dataWriter = try writer.makeDataWriter()
        
        guard let header = mergedBlastHits.first?.header else {
            throw RuntimeError("Unable to print merged minimap2 and BLASTn hits to file as no merged hits were found.")
        }
        
        dataWriter.write(line: header)
        for mergedBlastHit in mergedBlastHits {
            dataWriter.write(line: mergedBlastHit.description)
        }
    }
    
    private func resolveOutputMergedFilePath() -> String {
        if let outputMergedFile = self.outputMergedFile,
           outputMergedFile.resolvedFileURL() != nil {
            return outputMergedFile
        } else {
            return FilePrefix.blast.rawValue + FileSuffix.report.rawValue
        }
    }
    
    private func resolveOutputHitCountsFilePath() -> String {
        if let outputHitCountsFile = self.outputHitCountsFile,
           outputHitCountsFile.resolvedFileURL() != nil {
            return outputHitCountsFile
        } else {
            return FilePrefix.blast.rawValue + FileSuffix.hitcounts.rawValue
        }
    }
}
