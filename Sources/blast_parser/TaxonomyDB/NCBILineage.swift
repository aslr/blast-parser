//
//  NCBILineage.swift
//  blast_parser
//
//  Created by João Varela on 18/11/2024.
//

import Foundation

struct NCBILineage {
    let taxId:Int
    let taxName:String
    let species:String
    let genus:String
    let family:String
    let order:String
    let `class`:String
    let phylum:String
    let kingdom:String
    let superkingdom:String
    
    init?(string:String) {
        let fields = string.components(separatedBy: kPSDQueryResultSeparator)
        guard fields.count == kPSDQueryFieldNumber else { return nil }
        self.taxId = Int(fields[0])!
        self.taxName = fields[1].trimmingCharacters(in: CharacterSet.whitespaces)
        self.species = fields[2].trimmingCharacters(in: CharacterSet.whitespaces)
        self.genus = fields[3].trimmingCharacters(in: CharacterSet.whitespaces)
        self.family = fields[4].trimmingCharacters(in: CharacterSet.whitespaces)
        self.order = fields[5].trimmingCharacters(in: CharacterSet.whitespaces)
        self.class = fields[6].trimmingCharacters(in: CharacterSet.whitespaces)
        self.phylum = fields[7].trimmingCharacters(in: CharacterSet.whitespaces)
        self.kingdom = fields[8].trimmingCharacters(in: CharacterSet.whitespaces)
        self.superkingdom = fields[9].trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    init?(database:SQLDatabase, taxID:Int) {
        let result = database.queryDatabase(sql: "tax_id = \(taxID)")
        self.init(string: result)
    }
}
