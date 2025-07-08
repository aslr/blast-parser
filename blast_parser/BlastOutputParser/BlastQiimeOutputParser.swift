//
//  BlastQiimeOutputParser.swift
//  blast_parser
//
//  Created by Catarina Alexandre on 29/05/2025.
//
import Foundation

final class BlastQiimeOutputParser: BlastOutputParser{
	let asvsParser: QiimeParser
	let taxonomyParser: QiimeParser? = nil
	var blastASVs = [BlastQiimeASV]()
	
	init?(path:String, asvs: String) {
		guard let asvsParser = QiimeParser(path: asvs)
		else { return nil }
		
		self.asvsParser = asvsParser
		super.init(path: path)
	}
	
	func parse(criterion:BlastHit.SortCriterion = .bitScore) throws {
		try parseBlastOutput()
		try parseBins(criterion: criterion)
		try merge()
	}
	
	func print(_ path:String) throws{
		let writer = FileWriter(path:path)
		let dataWriter = try writer.makeDataWriter()
		for blastASV in blastASVs {
			dataWriter.write(line: blastASV.description)
		}
		Console.writeToStdOut("Written merged Kraken2 and BLASTn output to file at \(dataWriter.url.path)")
	}
	
	private func parseBlastOutput() throws {
		Console.writeToStdOut("Parsing BLASTn output...")
		
		for line in readStream {
			let hit = try BlastHit(line: line)
			hits.append(hit)
		}
	}
	
	/// Parses the BLASTn output into bins with the same sequenceID
	/// Assumes the hits are sorted by their sequenceIDs
	private func parseBins(criterion:BlastHit.SortCriterion) throws {
		Console.writeToStdOut("Parsing BLASTn output into bins...")
		var previousID = String()
		for hit in hits {
			if hit.querySequenceID != previousID {
				let bin = BlastHitBin(hit: hit)
				bin.sort(criterion: criterion)
				bins.append(bin)
				previousID = hit.querySequenceID
			} else {
				if let previousBin = bins.last {
					previousBin.append(hit: hit)
				} else {
					throw RuntimeError("Unable to append BLAST hit to bin.")
				}
			}
		}
	}
	
	/// Merge Qiime 2 ASVs with BLASTn best hit(s) of each bin
	/// depending upon the `hitsPerASV` instance variable
	private func merge() throws {
		Console.writeToStdOut("Merging Qiime 2 ASVs with BLASTn output...")
		
		guard hits.isEmpty == false else {
			throw RuntimeError("Unable to merge BLAST hits with the ASVs table because no BLAST hits were found.")
		}
		
		let asvs = try asvsParser.parse()
		guard asvs.isEmpty == false else {
			throw RuntimeError("Unable to merge BLAST hits with the ASVs table because no ASVs were found.")
		}
		// Initialize the object that will connect to the PostgresSQL
		// database containing the whole NCBI taxonomic lineages
		let taxonomyDatabase = SQLDatabase(database: taxonomyDatabase,
										   table: taxonomyTable)
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
			
			if queryID == asv.featureID {
				// retrieve the best hit(s)
				guard let bestHits = bin.bestHits(hitsPerASV) else { continue }
				for hit in bestHits {
					let blastASV = BlastQiimeASV(asv: asv, hit: hit)
					blastASV.setBlastTaxonomy(database: taxonomyDatabase)
					try blastASV.merge()
					blastASVs.append(blastASV)
				}
				index = bins.index(after: index)
			} else {
				// no BLAST hit was found for this ASV, so generate and
				// append an "Unclassified" BlastHit
				let blastASV = BlastQiimeASV(asv: asv, hit: BlastHit())
				blastASVs.append(blastASV)
			}
		}
		
		taxonomyDatabase.disconnect()
	}
}
