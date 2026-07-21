//
//  Import.swift
//  blast-parser
//
//  Created by João Varela on 29/05/2026.
//

import Foundation
import ArgumentParser
import Crypto

// 1. Linux-compatible networking import
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct Import: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Downloads and imports the NCBI ranked taxonomy dump file into an indexed CSV file.",
        usage: "blast_parser import <output-path>]",
        aliases: ["imp"]
    )
    
    @Argument(help: "The directory path where the taxonomy file should be saved and extracted.")
    var outputPath: String

    // Hardcoded Secure URLs
    private static let payloadURL = URL(string: "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz")!
    private static let md5URL = URL(string: "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz.md5")!
    private static let dumpFileName = "rankedlineage.dmp"

    func run() async throws {
        try await download()
        try export()
    }
    
    // download NCBI rankedlineage.dmp file from NCBI
    func download() async throws {
        let fileManager = FileManager.default
        
        // 1. Set URL from path
        let destinationDir = URL(fileURLWithPath: outputPath)
        
        // 2. Ensure the resolved directory exists but the file does not
        if fileManager.fileExists(atPath: destinationDir.path) {
            let cvsFilePath = destinationDir.appendingPathComponent(Self.dumpFileName).path
            guard !fileManager.fileExists(atPath: cvsFilePath) else {
                print("Taxonomy dump file already exists in the specified directory.")
                return
            }
        } else {
            try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        }

        // --- STEP 1: Download expected MD5 hash ---
        print("Fetching remote MD5 signature...")
        let md5Data = try await NCBIDownloader.fetchData(from: Self.md5URL)
        
        guard let remoteMD5String = String(data: md5Data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ").first else {
                throw ValidationError("Could not parse remote MD5 string.")
        }
        
        // --- STEP 2: Download Tarball Payload with Progress Bar ---
        print("Connecting to NCBI servers for new_taxdump tar file...")
        let archiveData = try await NCBIDownloader.fetchDataWithProgress(from: Self.payloadURL)

        // --- STEP 3: Verify Cryptographic Integrity ---
        print("Verifying MD5 checksum integrity...")
        let calculatedDigest = Insecure.MD5.hash(data: archiveData)
        let localMD5String = calculatedDigest.map { String(format: "%02hhx", $0) }.joined()
        
        guard localMD5String.lowercased() == remoteMD5String.lowercased() else {
            print("CRITICAL SECURITY ERROR: MD5 hash mismatch!")
            throw ExitCode.failure
        }
        print("Integrity verified successfully.")

        // Write tarball to an intermediary tmp file inside your destination
        let tarballURL = destinationDir.appendingPathComponent("new_taxdump.tar.gz")
        try archiveData.write(to: tarballURL, options: .atomic)

        // --- STEP 4: Decompress and Untar safely across platforms ---
        print("Extracting tarball via system shell...")
        try Utilities.executeTarCommand(archiveURL: tarballURL, targetDirectory: destinationDir)
        
        // Clean up the downloaded raw archive container immediately
        try fileManager.removeItem(at: tarballURL)

        // --- STEP 5: Purge all files except 'rankedlineage.dmp' ---
        print("Cleaning up target directory, keeping only '\(Self.dumpFileName)'...")
        let contents = try fileManager.contentsOfDirectory(at: destinationDir, includingPropertiesForKeys: nil)
        
        for fileURL in contents {
            if fileURL.lastPathComponent != Import.dumpFileName {
                try fileManager.removeItem(at: fileURL)
            }
        }
        
        print("Done. Dump file downloaded and extracted successfully at: \(destinationDir.appendingPathComponent(Self.dumpFileName).path)")
    }
    
    // export the rankedlineage.dmp file to a CSV file, index it and test it
    func export() throws {
        let fileManager = FileManager.default
        let destinationDir = URL(fileURLWithPath: outputPath)
        let dumpFileURL = destinationDir.appendingPathComponent(Self.dumpFileName)
        
        if !fileManager.fileExists(atPath: dumpFileURL.path) {
            throw ValidationError("No dump file found at \(dumpFileURL.path).")
        }
        
        let csvFileURL = destinationDir.appendingPathComponent(Self.dumpFileName.replacingOccurrences(of: ".dmp", with: ".csv"))
        
        let database = Database()
        try database.parse(path: dumpFileURL.path, outputPath: csvFileURL.path)
        
        let indexFileURL = destinationDir.appendingPathComponent(Self.dumpFileName.replacingOccurrences(of: ".dmp", with: ".idx"))
        try database.createIndexFile(from: csvFileURL.path, to: indexFileURL.path)
        try database.load(csvPath: csvFileURL.path, indexPath: indexFileURL.path)
        
        if let result = database.getRecord(for: 9606) {
            result.dump()
            print("Directly extracted order field: \(result.order)")
        }
    }
}