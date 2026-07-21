//
//  DataStreamReader.swift
//  blast_parser
//
//  Created by João Varela on 30/08/2024.
//

import Foundation

enum DataStreamReaderError: Error {
    case delimiterError
    case readError
}

// Heavily borrowed from Martin R's answer at:
// https://stackoverflow.com/questions/24581517/read-a-file-url-line-by-line-in-swift
final class DataStreamReader : DataStream {
    var buffer:Data
    var delimiter:Data
    var isEOF = false
    let encoding:String.Encoding
    
    /// Must be paired with a call to close()
    init(url:URL, delimiter:String = "\n",
          blockSize:Int = 4096,
          encoding:String.Encoding = .utf8) throws {
        do {
            guard let dataDelimiter = delimiter.data(using: encoding)
                else { throw DataStreamReaderError.delimiterError }
            self.delimiter = dataDelimiter
            self.encoding = encoding
            buffer = Data()
            try super.init(url: url, blockSize: blockSize)
            filehandle = try FileHandle(forReadingFrom: url)
        }
        
        catch {
            throw DataStreamReaderError.readError
        }
    }
    
    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        // Read data chunks from file until a line delimiter is found:
        while isEOF == false {
            if let range = buffer.range(of: delimiter) {
                // Convert complete line (excluding the delimiter) to a string:
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), 
                                  encoding: encoding)
                // Remove line (and the delimiter) from the buffer:
                buffer.removeSubrange(0..<range.upperBound)
                return line
            }
        
            let tmpData = filehandle.readData(ofLength: bufferSize)
            if tmpData.count > 0 {
                buffer.append(tmpData)
            } else {
                // EOF or read error.
                isEOF = true
                if buffer.count > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer as Data, encoding: encoding)
                    buffer.count = 0
                    return line
                }
            }
        }
        return nil
    }
    
    /// Start reading from the beginning of file.
    func rewind() -> Void {
        filehandle.seek(toFileOffset: 0)
        buffer.count = 0
        isEOF = false
    }
}

extension DataStreamReader : Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.nextLine()
        }
    }
}
