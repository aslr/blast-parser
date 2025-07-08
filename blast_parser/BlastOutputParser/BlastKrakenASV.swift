//
//  BlastKrakenASV.swift
//  blast_parser
//
//  Created by João Varela on 17/11/2024.
//

import Foundation

enum BlastASVError: Error {
    case invalidLineage
}

class BlastASV: CustomStringConvertible{
	var hit: BlastHit
	var blastTaxonomy = Hierarchy()
	
	var description: String{
		return "\(hit)\t\(blastTaxonomy)"
	}
	
	init(hit: BlastHit) {
		self.hit = hit
	}
}

class BlastKrakenASV: BlastASV {
    let asv:KrakenASV
    
    /// Initializer to merge a parsed Kraken2 ASV and a BLASTn hit
    /// used by BlastOutputParser
    /// - parameters:
    ///     - asv: a Kraken2 ASV parsed by the subcommand `parser`
    ///     - hit: a 13-column BLASTn hit
    /// Refer to BlastHit and BlastOutputParser for the full format
    /// of the BLASTn hit
    init(asv: KrakenASV, hit: BlastHit) {
        self.asv = asv
		super.init(hit:hit)
    }

    /// Initializer to parse an already merged ASV and BLASTn hit
    /// used by BlastAnalyzer
    /// - parameters:
    ///     - line: a BlastOutputParser output file line, which has the following layout:
    ///         - sequenceID:String         (KrakenASV)
    ///         - length:Int                (KrakenASV)
    ///         - assignedReads:Int         (KrakenASV)
    ///         - taxID:Int                 (KrakenASV)
    ///         - krakenTaxonomy:String     (KrakenASV)
    ///         - subjectSequenceID:Int     (BlastHit)
    ///         - percentageIdentity:Int    (BlastHit)
    ///         - bitscore:Int              (BlastHit)
    ///         - eValue:Double             (BlastHit)
    ///         - ncbiTaxID:Int             (BlastHit)
    ///         - scientificName:String     (BlastHit)
    ///         - blastTaxonomy:Hierarchy   (optional)
	init(line:String, asvFormat:ASVFormat, hit:BlastHit) throws {
        let components = line.components(separatedBy: "\t")
        let count = components.count
        guard count == 11 || count == 12  else {
            throw RuntimeError("Invalid BlastOutputParser line format")
        }
        
        var krakenLine = String()
        for component in components[0..<4] {
            krakenLine.append(component)
            krakenLine.append("\t")
        }
        krakenLine.append(components[4])
        self.asv = try KrakenASV(line: krakenLine, format: asvFormat)
        
        let range =  5..<(count-1)
        var blastLine = String()
        for component in components[range] {
            blastLine.append(component)
            blastLine.append("\t")
        }
        blastLine.append(components[range.upperBound])
		super.init(hit:hit)
		self.hit = try BlastHit(parsedLine: blastLine)
    }
    
    /// Sets Kraken2 taxonomy:
    /// - parameters:
    ///   - taxonomy: string containing a parser-subcommand parsed lineage
    ///   If `taxonomy` is nil, it does nothing
    func setKrakenTaxonomy(_ taxonomy:String?) {
        do {
            if let taxonomy {
                blastTaxonomy = try Hierarchy(lineageString: taxonomy)
            }
        }
        
        catch {
            Console.writeToStdErr("Invalid taxonomy for sequence \(asv.sequenceID)")
        }
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
    
    override var description:String {
        let blastRanks = blastTaxonomy.getRanks()
        if blastRanks.isEmpty == false {
            return "\(asv)\t\(hit)\t\(blastRanks)"
        } else {
            return "\(asv)\t\(hit)"
        }
    }
}
