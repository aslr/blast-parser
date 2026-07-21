//
//  FileWriter.swift
//  blast_parser
//
//  Created by João Varela on 09/11/2024.
//

import Foundation

struct FileWriter {
	let path:String
	let outputURL:URL
	
	/// Generates a data stream writer without any changes to the path
	/// - Parameter path: path to file to write data to
	init?(path: String){
        guard let resolvedURL = path.resolvedFileURL() else { return nil }
        self.path = resolvedURL.path
        self.outputURL = URL(fileURLWithPath: self.path, isDirectory: false)
	}
    
    /// Generates a data stream writer where the path will be edited by adding a suffix
    /// - Parameters:
    ///  - path: path to file to write data to
    ///  - suffix: suffix to add to filename, which will be based on the name of the sequence output directory (2 levels up)
    init?(path:String, suffix:String) {
        guard let resolvedURL = path.resolvedFileURL() else { return nil }
        self.path = resolvedURL.path
        let url = URL(fileURLWithPath: self.path, isDirectory: false)
        let directoryURL = url.deletingLastPathComponent()
        let parentDirectoryURL = directoryURL.deletingLastPathComponent()
        let directoryName = parentDirectoryURL.lastPathComponent
        let filename = "\(directoryName)_\(suffix)"
        outputURL = directoryURL.appending(component: filename)
    }
    
    func makeDataWriter() throws -> DataStreamWriter {
        return try DataStreamWriter(url: outputURL)
    }
}
