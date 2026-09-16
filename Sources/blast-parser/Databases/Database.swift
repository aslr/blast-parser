//
//  Database.swift
//  blast_parser
//
//  Created by João Varela on 30/08/2024.
//

import Foundation
import ArgumentParser

/// Model holding the fields for an imported NCBI Lineage row
struct TaxonRecord {
    let taxonomyID: Int
    let taxonName: String
    let species: String
    let genus: String
    let family: String
    let order: String
    let `class`: String
    let phylum: String
    let kingdom: String
    let superkingdom: String
    
    func dump() {
        print("""
        ------------------------------------------
        Taxonomy ID:  \(taxonomyID)
        Name:         \(taxonName)
        Species:      \(species)
        Genus:        \(genus)
        Family:       \(family)
        Order:        \(order)
        Class:        \(self.class)
        Phylum:       \(phylum)
        Kingdom:      \(kingdom)
        Superkingdom: \(superkingdom)
        ------------------------------------------
        """)
    }
}

final class Database {
    // In-memory index map lookup table [TaxonomyID: ByteOffset]
    private var indexMap: [Int: UInt64] = [:]
    
    // An active stream reader kept ready for random-access queries
    private var liveReadStream: DataStreamReader?
    
    deinit {
        liveReadStream?.close()
    }
    
    // MARK: - 1. Indexing
    // Index the CSV table according to the taxonomy ID
    func createIndexFile(from path:String, to outputPath:String) throws {
        print("\nGenerating byte-offsets...")
        
        let url = URL(fileURLWithPath: path)
        let outURL = URL(fileURLWithPath: outputPath)
        
        do {
            let readStream:DataStreamReader = try DataStreamReader(url: url)
            let writeStream:DataStreamWriter = try DataStreamWriter(url: outURL)
            
            var totalRecords = 0

            // To get the absolute accurate offset when using the Sequence iterator,
            // we track the baseline offset manually as we consume lines.
            var rollingOffset: UInt64 = 0

            for line in readStream {
                // Extract the first field (Taxonomy ID)
                let firstField = line.prefix(while: { $0 != "," && $0 != "\r" })
                if let taxID = Int(firstField.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    writeStream.write(line: "\(taxID),\(rollingOffset)")
                    totalRecords += 1
                }
                
                // Advance our rolling byte counter by the length of the string plus 1 byte for the delimiter '\n'
                if let lineData = line.data(using: readStream.encoding) {
                    rollingOffset += UInt64(lineData.count + 1)
                }
            }

            Console.writeToStdOut("\nIndexed \(totalRecords) records successfully. Bye!")
        }
       
        catch DataStreamReaderError.delimiterError {
            throw ValidationError("\nUnable to use delimiter for file at \(url.path)")
        }
        
        catch DataStreamReaderError.readError {
            throw ValidationError("\nUnable to read file at \(url.path)")
        }
        
        catch {
            throw ValidationError("\n\(error.localizedDescription)")
        }
    }
    
    // MARK: - 2. Loading the Index Maps
    /// Loads a previously generated text-based index file into the memory mapping dictionary
    /// and opens a permanent live data handle to the CSV table for lookups.
    /// - Parameters:
    ///  - csvPath: path to the lineage database (CSV table)
    ///  - indexPath: path to index file; if nil, expects the index file to have the same name as the database but with a .idx extension
    func load(csvPath: String, indexPath: String? = nil) throws {
        let csvURL = URL(fileURLWithPath: csvPath)
        var indexURL: URL? = nil
        
        if indexPath == nil {
            indexURL = csvURL.deletingPathExtension().appendingPathExtension("idx")
        } else {
            indexURL = URL(fileURLWithPath: indexPath!)
        }
        
        do {
            print("\nLoading text-based index into memory mapping...")
            let indexReader = try DataStreamReader(url: indexURL!)
            
            // Loop through the index lines
            for line in indexReader {
                let components = line.components(separatedBy: ",")
                guard components.count >= 2,
                      let taxID = Int(components[0].trimmingCharacters(in: .whitespacesAndNewlines)),
                      let byteOffset = UInt64(components[1].trimmingCharacters(in: .whitespacesAndNewlines)) else {
                    continue
                }
                indexMap[taxID] = byteOffset
            }
            indexReader.close()
            
            // Retain a dedicated stream reader targeting the raw CSV for fast random access lookups
            self.liveReadStream = try DataStreamReader(url: csvURL)
            
            Console.writeToStdOut("\nReady. Memory mapped \(indexMap.count) entries.")
        } catch {
            throw ValidationError("\nFailed to initialize database structures: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 3. Record Retrieval Lookups
    /// Uses low-RAM file seeking to pull fields dynamically for a given Taxonomy ID
    func getRecord(for taxonomyID: Int) -> TaxonRecord? {
        // Step A: Ensure the index contains the key and our live stream handle is open
        guard let targetOffset = indexMap[taxonomyID], let stream = liveReadStream else {
            return nil
        }
        
        do {
            // Step B: Direct jump inside the file handle via your stream class
            try stream.filehandle.seek(toOffset: targetOffset)
            
            // Reset stream state buffers safely so nextLine parses freshly from our new location
            stream.buffer.removeAll(keepingCapacity: true)
            stream.isEOF = false
            
            // Step C: Harvest just that single target record line
            guard let line = stream.nextLine() else { return nil }
            
            let fields = line.components(separatedBy: ",")
            
            // Safe fallback bounds checking helper closure
            func getField(_ index: Int) -> String {
                guard fields.indices.contains(index) else { return "" }
                return fields[index].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            return TaxonRecord(
                taxonomyID:   taxonomyID,
                taxonName:    getField(1),
                species:      getField(2),
                genus:        getField(3),
                family:       getField(4),
                order:        getField(5),
                class:        getField(6),
                phylum:       getField(7),
                kingdom:      getField(8),
                superkingdom: getField(9)
            )
            
        } catch {
            Console.writeToStdErr("Error executing record seek operation: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 4. Parsing Dump
    // parse the NCBI lineage dump file into a proper CSV table
    func parse(path:String, outputPath:String) throws {
        let url = URL(fileURLWithPath: path)
        let outURL = URL(fileURLWithPath: outputPath)
        
        do {
            let readStream:DataStreamReader = try DataStreamReader(url: url)
            let writeStream:DataStreamWriter = try DataStreamWriter(url: outURL)
            for line in readStream {
                writeStream.write(line: parseLine(line: line))
            }

            Console.writeToStdOut("\nWritten all lines successfully. Bye!")
        }
       
        catch DataStreamReaderError.delimiterError {
            throw ValidationError("Unable to use delimiter for file at \(url.path)")
        }
        
        catch DataStreamReaderError.readError {
            throw ValidationError("Unable to read file at \(url.path)")
        }
        
        catch {
            throw ValidationError("\(error.localizedDescription)")
        }
    }
    
    private func parseLine(line:String) -> String {
        var filteredLine = line.replacingOccurrences(of: "\t", with: "")
        filteredLine = filteredLine.replacingOccurrences(of: "\"", with: "")
        filteredLine = filteredLine.replacingOccurrences(of: ",", with: " ")
        filteredLine = filteredLine.replacingOccurrences(of: "|", with: ",")
        return filteredLine
    }
}
