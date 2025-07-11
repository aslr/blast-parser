//
//  BlastQiimeASV.swift
//  blast_parser
//
//  Created by Catarina Alexandre on 16/06/2025.
//

import Foundation

class BlastQiimeASV: BlastASV {
	let asv: QiimeASV
	var items: [String]
	init(asv: QiimeASV, hit: BlastHit) {
		self.asv = asv
		self.items = asv.description.components(separatedBy: "\t")
		super.init(hit: hit)
	}
	
	/// Sets BLASTn taxonomy:
	/// - parameters:
	///   - database: SQLDatabase object that handles all calls
	///   to the PostgresSQL taxonomic database imported by the `import` and
	///   `export` subcommands.
	func setBlastTaxonomy(database:SQLDatabase) {
		let taxID = self.hit.ncbiTaxID
		do {
			if let lineage = NCBILineage(database: database, taxID: taxID) {
				blastTaxonomy = try Hierarchy(lineage: lineage)
				
				if lineage.species.isEmpty {
					let species = try Rank.rank(abbreviation: "S",
												name: hit.scientificName)
					blastTaxonomy.dropLastRank()
					blastTaxonomy.addRank(species)
				}
			} else if taxID != 0 {
				// if taxID == 0 then blastTaxonomy is already inited
				// with an "Unclassified" Rank, so we do nothing, but
				// otherwise any other taxID is an error.
				throw BlastASVError.invalidLineage
			}
		}
		
		catch {
			Console.writeToStdErr("Invalid taxonomy for tax_id = \(taxID)")
		}
	}
    
	func merge() throws {
		let blastRanks = blastTaxonomy.getRanks()
        
        switch asv.featureID {
        case "id":
            // handle the header
            items.insert("E-Value", at: 1)
            items.insert("BitScore", at: 1)
            items.insert("NCBI lineage", at: 1)
        case "":
            items.insert("no hits", at: 1)
            items.insert("no hits", at: 1)
            items.insert("no hits", at: 1)
        default:
            // merge ASV with BLAST hit
            items.insert(String(hit.eValue), at: 1)
            items.insert(String(hit.bitscore), at: 1)
            items.insert(blastRanks, at: 1)
        }
	}
	
	override var description:String {
		return items.joined(separator: "\t")
	}
}
