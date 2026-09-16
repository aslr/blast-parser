//
//  File.swift
//  blast-parser
//
//  Created by João Varela on 29/05/2026.
//

import Foundation
import ArgumentParser

class DataStream {
    let url:URL
    var filehandle:FileHandle!
    let bufferSize:Int
    
    init(url:URL, blockSize:Int = 4096) throws {
        guard let resolvedURL = url.path.resolvedFileURL() else {
            throw ValidationError("DataStream Error: Unable to find file at path: \(url.path)")
        }
        self.url = resolvedURL
        self.bufferSize = blockSize
    }
    
    deinit {
        close()
    }
    
    func close() {
        do {
            try filehandle?.close()
        }
        
        catch {
            Console.writeToStdErr("Unable to close file at \(url.path)")
        }
    }
}
