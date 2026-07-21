//
//  Console.swift
//  blast_parser
//
//  Created by João Varela on 12/07/2024.
//

import Foundation

class Console {
    static func getArgs() -> [String] {
        return CommandLine.arguments
    }
    
    static func writeToStdErr(_ message:String) {
        FileHandle.standardError.write("\(message)\n")
    }
    
    static func writeToStdOut(_ message:String) {
        FileHandle.standardOutput.write("\(message)\n")
    }
    
    static func writeToStdOutInPlace(_ message:String) {
        FileHandle.standardOutput.write("\(message)\r")
    }
}

extension FileHandle: @retroactive TextOutputStream {
  public func write(_ string: String) {
    let data = Data(string.utf8)
    self.write(data)
  }
}

// MARK: Errors
struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}

