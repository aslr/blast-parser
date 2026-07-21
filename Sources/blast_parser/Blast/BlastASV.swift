//
//  BlastASV.swift
//  blast_parser
//
//  Created by João Varela on 03/01/2026.
//

/// Base class to store taxonomy information to a BlastHit and to be used
/// by derived classes to merge it with data from other classifiers and
/// databases
class BlastASV: CustomStringConvertible {
    var hit: BlastHit
    var blastTaxonomy = Hierarchy()
    
    var description: String {
        return "\(hit.description)\t\(blastTaxonomy.description)"
    }
    
    var header: String? {
        return "\(hit.header)\tNCBI_Taxonomy"
    }
    
    init(hit: BlastHit) {
        self.hit = hit
    }
    
    /// Sets BLASTn taxonomy:
    /// - parameters:
    ///   - database: SQLDatabase object that handles all calls
    ///   to the PostgresSQL taxonomic database imported by the `import` and
    ///   `export` subcommands.
    func setBlastTaxonomy(database:Database) {
        let taxID = self.hit.ncbiTaxID
        do {
            if let lineage = database.getRecord(for: taxID) {
                blastTaxonomy = try Hierarchy(lineage: lineage)
                
                if lineage.species.isEmpty {
                    let species = try KrakenRank.rank(abbreviation: "S",
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
}
