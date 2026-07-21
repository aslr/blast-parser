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
    
    static func writeToStdErr(_ message: String) {
        FileHandle.standardError.write("\(message)\n")
    }
    
    static func writeToStdOut(_ message: String) {
        FileHandle.standardOutput.write("\(message)\n")
    }

    /// Overwrites the current terminal line in place (no newline appended).
    /// The caller is responsible for passing a string that starts with \r.
    static func writeToStdOutInPlace(_ message: String) {
        // Write exactly what we are given — no \n appended.
        // The \r at the start of `message` returns the cursor to column 0,
        // and the absence of \n keeps subsequent writes on the same line.
        FileHandle.standardOutput.write(message)

        // Flush stdout explicitly.  On Linux stdout is fully buffered when
        // it is not a TTY (e.g. piped), so without this the bar never appears.
        _ = Foundation.fflush(nil)
    }
}

extension FileHandle: @retroactive TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        self.write(data)
    }
}

