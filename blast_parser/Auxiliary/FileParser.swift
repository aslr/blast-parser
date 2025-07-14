//
//  FileParser.swift
//  blast_parser
//
//  Created by João Varela on 03/11/2024.
//

import Foundation

class FileParser {
    let path:String
    let readStream:DataStreamReader
    
    init?(path: String) {
        do {
            self.path = path
            let url = URL(fileURLWithPath: path)
            self.readStream = try DataStreamReader(url: url)
        }
        
        catch {
            Console.writeToStdErr("Unable to read file at \(path)")
            return nil
        }
    }
}

class FilesParser {
    let parsers:[FileParser]
    
    init?(paths: String) {
        let pathsArray = paths.components(separatedBy: " ")
        self.parsers = pathsArray.compactMap { path in FileParser(path: path) }
        guard parsers.count == pathsArray.count else { return nil }
    }
}
