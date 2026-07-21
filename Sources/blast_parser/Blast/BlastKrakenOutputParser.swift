//
//  BlastKrakenOutputParser.swift
//  blast_parser
//
//  Created by João Varela on 03/11/2024.
//

import Foundation

final class BlastKrakenOutputParser: BlastOutputParser {
    let asvsParser:KrakenParsedASVParser
    var taxonomyParser:KrakenTaxonomyParser? = nil
    var blastASVs = [BlastKrakenASV]()

    /// Initializer for a parser that will merge the output files of the parse
    /// subcommand with the BLASTn output file which should have the following
    /// 13 columns:
    /// A: qseqid = Query Seq-id (ID of your sequence)
    /// B: pident = Percentage of identical matches
    /// C: length = Alignment length
    /// D: evalue = Expected value (E-value)
    /// E: bitscore = Bit score
    /// F: score = Raw score
    /// G: nident = Number of identical matches
    /// H: saccver = Subject accession.version
    /// I: stitle = Subject Title
    /// J: qcovs = Query Coverage Per Subject
    /// K: staxids = unique Subject Taxonomy ID(s), separated by a ';' (in numerical order)
    /// L: sscinames = unique Subject Scientific Name(s), separated by a ';'
    /// M: sskingdoms = unique Subject Super Kingdom(s), separated by a ';' (in alphabetical order)
    /// - Parameters:
    ///     - path: path to the BLASTn output file
    ///     - asvs: path to parsed ASVs with taxonomic classification
    ///     - taxonomy: path to the parsed Kraken2 count file (optional)
    init?(path:String, asvs: String, taxonomy: String?) {
        guard let asvsParser = KrakenParsedASVParser(path: asvs)
            else { return nil }
        
        self.asvsParser = asvsParser
        
        if let taxonomy = taxonomy {
            self.taxonomyParser = KrakenTaxonomyParser(path: taxonomy)
        }
        
        super.init(path: path)
    }
    
    func print(to path:String? = nil) throws {
        var writer:FileWriter?
        
        if let path = path {
            writer = FileWriter(path: path)
        } else {
            writer = FileWriter(path: asvsParser.path,
                                suffix: FileSuffix.report.rawValue)
        }
        
        guard let writer = writer else {
            throw RuntimeError("Unable to open file to write BLASTn and Kraken2 output due to a malformed path.")
        }
        
        let dataWriter = try writer.makeDataWriter()
        for blastASV in blastASVs {
            dataWriter.write(line: blastASV.description)
        }
        Console.writeToStdOut("Written merged Kraken2 and BLASTn output to file at \(dataWriter.url.path)")
    }
    
    /// Merge Kraken ASVs with BLASTn best hit(s) of each bin
    /// depending upon the `hitsPerASV` instance variable
    override func merge() throws {
        Console.writeToStdOut("Merging Kraken ASVs with BLASTn output...")
        
        guard hits.isEmpty == false else {
            throw RuntimeError("Unable to merge BLAST hits with the ASVs table because no BLAST hits were found.")
        }
        
        let asvs = try asvsParser.parse()
        guard asvs.isEmpty == false else {
            throw RuntimeError("Unable to merge BLAST hits with the ASVs table because no ASVs were found.")
        }
        
        try taxonomyParser?.parse()
        
        // Initialize the object that will connect to the PostgresSQL
        // database containing the whole NCBI taxonomic lineages
        let taxonomyDatabase = SQLDatabase(database: .database,
                                           table: .table)
        taxonomyDatabase.connect()
        
        // We get the current index to make the search faster in the ASVs table
        // and avoid searching the same hits all over again for each ASV as we
        // assume that the BLAST hits are in the same order as the ASV table
        // regarding the query sequence IDs
        var index = bins.startIndex
        for asv in asvs {
            guard index < bins.endIndex else { break }
            let bin = bins[index]
            guard let queryID = bin.sequenceID else {
                throw RuntimeError("Unable to merge BLAST hits with the ASVs table because at least one BLAST hit does not have a sequence ID.")
            }
            
            if queryID == asv.sequenceID {
                // retrieve the best hit(s)
                guard let bestHits = bin.bestHits(hitsPerASV) else { continue }
                for hit in bestHits {
                    let taxonomy = taxonomyParser?.getTaxonomy(for: asv)
                    let blastASV = BlastKrakenASV(asv: asv, hit: hit)
                    blastASV.setKrakenTaxonomy(taxonomy)
                    blastASV.setBlastTaxonomy(database: taxonomyDatabase)
                    blastASVs.append(blastASV)
                }
                index = bins.index(after: index)
            } else {
                // no BLAST hit was found for this ASV, so generate and
                // append an "Unclassified" BlastHit
                let taxonomy = taxonomyParser?.getTaxonomy(for: asv)
                let blastASV = BlastKrakenASV(asv: asv, hit: BlastHit())
                blastASV.setKrakenTaxonomy(taxonomy)
                blastASVs.append(blastASV)
            }
        }
        
        taxonomyDatabase.disconnect()
    }
}

