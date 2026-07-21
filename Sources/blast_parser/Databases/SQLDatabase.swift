//
//  SQLDatabase.swift
//  blast_parser
//
//  Created by João Varela on 01/09/2024.
//

import Foundation

// MARK: Taxonomy Database
enum TaxonomyDatabase: String {
    case database = "taxonomy_ncbi"
    case table = "taxonomy"
}

final class SQLDatabase {
    let database:String
    let table:String?
    let columns = """
            tax_id int PRIMARY KEY NOT NULL,
            tax_name varchar(255) NOT NULL,
            species varchar(100),
            genus varchar(100),
            family varchar(100),
            "order" varchar(100),
            "class" varchar(100),
            phylum varchar(100),
            kingdom varchar(100),
            superkingdom varchar(100),
            comments varchar(50)
        """
    let bufferSize = Int(kPSDMaxBufferSize)
    
    init(database:TaxonomyDatabase, table:TaxonomyDatabase?) {
        self.database = database.rawValue
        self.table = table?.rawValue
    }
    
    func connect() {
        PSDBegin(database)
    }
    
    func disconnect() {
        PSDEnd()
    }
    
    func createDatabase() {
        PSDBeginWithDefaultDB();
        if PSDDoesExist(database) == true {
            PSDDeleteDatabase(database)
        }
        // This method swicthes automatically to the newly created db
        // to create the requested table
        let table = self.table ?? "taxonomy"
        PSDCreateDatabase(database, table, columns)
        Console.writeToStdOut("Database \"\(database)\" and table \"\(table)\" created successfully.")
    }
    
    func importDatabase(pathToCSVFile:String) {
        let table = self.table ?? "taxonomy"
        PSDCopyToDB(table, pathToCSVFile)
        Console.writeToStdOut("Table \"\(table)\" exported successfully.")
    }
    
    func queryDatabase(sql:String) -> String {
        var reply = [CChar](repeating: 0, count: bufferSize)
        PSDQuery(table, sql, &reply)
        let result = String(cString: reply)
        return result
    }
}
