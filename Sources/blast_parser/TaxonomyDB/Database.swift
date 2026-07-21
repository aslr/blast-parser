//
//  Database.swift
//  blast_parser
//
//  Created by João Varela on 30/08/2024.
//

import Foundation

final class Database {
    let readStream:DataStreamReader
    let writeStream:DataStreamWriter
    
    init(path:String, outputPath:String) {
        let url = URL(fileURLWithPath: path)
        let outURL = URL(fileURLWithPath: outputPath)
        do {
            self.readStream = try DataStreamReader(url: url)
            self.writeStream = try DataStreamWriter(url: outURL)
        }
        
        catch DataStreamReaderError.delimiterError {
            Console.writeToStdErr("Unable to use delimiter for file at \(url.path)")
            exit(1)
        }
        
        catch DataStreamReaderError.readError {
            Console.writeToStdErr("Unable to read file at \(url.path)")
            exit(2)
        }
        
        catch {
            Console.writeToStdErr("\(error.localizedDescription)")
            exit(3)
        }
    }
    
    func parse() {
        for line in readStream {
            writeStream.write(line: parseLine(line: line))
        }

        Console.writeToStdOut("\nWritten all lines successfully. Bye!")
    }
    
    private func parseLine(line:String) -> String {
        var filteredLine = line.replacingOccurrences(of: "\t", with: "")
        filteredLine = filteredLine.replacingOccurrences(of: "\"", with: "")
        filteredLine = filteredLine.replacingOccurrences(of: ",", with: " ")
        filteredLine = filteredLine.replacingOccurrences(of: "|", with: ",")
        return filteredLine
    }
}
