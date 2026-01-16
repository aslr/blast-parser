//
//  String.swift
//  blast_parser
//
//  Created by João Varela on 29/12/2025.
//


import Foundation

//// Example 1: Resolve absolute path
//let absolutePath = "/Users/username/Documents/file.txt"
//if let url = absolutePath.resolvedFileURL() {
//    print("Absolute URL: \(url.path)")
//}
//
//// Example 2: Resolve relative path (uses current directory)
//let relativePath = "subfolder/file.txt"
//if let url = relativePath.resolvedFileURL() {
//    print("Resolved URL: \(url.path)")
//}
//
//// Example 3: Resolve relative path with custom base
//let customBase = URL(fileURLWithPath: "/Users/username/project")
//if let url = "data/config.json".resolvedFileURL(relativeTo: customBase) {
//    print("Custom base URL: \(url.path)")
//}
//
//// Example 4: Handle paths with .. and .
//let complexPath = "./subfolder/../other/file.txt"
//if let url = complexPath.resolvedFileURL() {
//    print("Standardized URL: \(url.path)")
//}
//
//// Example 5: Expand tilde (~) for home directory
//let homePath = "~/Documents/notes.txt"
//if let url = homePath.resolvedFileURL() {
//    print("Home URL: \(url.path)")
//}
//
//// Example 6: Check if file exists
//let testPath = "README.md"
//if let url = testPath.existingFileURL() {
//    print("File exists at: \(url.path)")
//} else {
//    print("File not found")
//}
//
//// Example 7: Check path type
//print("Is '/usr/bin' absolute? \(("/usr/bin" as String).isAbsolutePath)")
//print("Is 'folder/file' relative? \(("folder/file" as String).isRelativePath)")
//print("Is '~/Desktop' absolute? \(("~/Desktop" as String).isAbsolutePath)")
//
//// MARK: - Advanced Usage with Error Handling
//
//func processFile(at pathString: String, relativeTo base: URL? = nil) -> Result<URL, PathError> {
//    guard let url = pathString.resolvedFileURL(relativeTo: base) else {
//        return .failure(.invalidPath(pathString))
//    }
//    
//    guard FileManager.default.fileExists(atPath: url.path) else {
//        return .failure(.fileNotFound(url.path))
//    }
//    
//    return .success(url)
//}
//
//enum PathError: Error, CustomStringConvertible {
//    case invalidPath(String)
//    case fileNotFound(String)
//    
//    var description: String {
//        switch self {
//        case .invalidPath(let path):
//            return "Invalid path: \(path)"
//        case .fileNotFound(let path):
//            return "File not found: \(path)"
//        }
//    }
//}
//
//// Usage with error handling
//let paths = ["/etc/hosts", "config.json", "~/Documents/data.txt", "../parent/file.txt"]
//
//for path in paths {
//    switch processFile(at: path) {
//    case .success(let url):
//        print("✓ Successfully resolved: \(url.path)")
//    case .failure(let error):
//        print("✗ Error: \(error)")
//    }
//}

// MARK: Paths
extension String {
    /// Converts path to URL and checks if it exists in the file system
    /// - Parameter base: Optional base URL for relative paths
    /// - Returns: Resolved URL if path exists, nil otherwise
    func existingFileURL(relativeTo base: URL? = nil) -> URL? {
        guard let url = resolvedFileURL(relativeTo: base) else { return nil }
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    /// Expands tilde (~) to home directory path
    private func expandingTilde() -> String {
        if self.hasPrefix("~/") {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            return homeDir + self.dropFirst(1)
        } else if self == "~" {
            return FileManager.default.homeDirectoryForCurrentUser.path
        }
        return self
    }
    
    /// Returns true if the string represents an absolute path
    var isAbsolutePath: Bool {
        let expanded = self.expandingTilde()
        return expanded.hasPrefix("/") || expanded.hasPrefix("file://")
    }
    
    // Returns nil if file or directory do not exist
    var isDirectory: Bool? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: self,
                                             isDirectory: &isDir)
            else { return nil }
        return isDir.boolValue
    }
    
    /// Returns true if the string represents a relative path
    var isRelativePath: Bool {
        return !isAbsolutePath && !self.isEmpty
    }
    
    /// Converts a string path (absolute or relative) to a fully resolved URL
    /// - Parameter base: Optional base URL. If nil, uses current directory for
    /// relative paths
    /// - Returns: A standardized, absolute file URL, or nil if the path is invalid
    func resolvedFileURL(relativeTo base: URL? = nil) -> URL? {
        // Handle empty strings
        guard !self.isEmpty else { return nil }
        
        // Expand tilde for home directory
        let expandedPath = self.expandingTilde()
        
        // Check if path is already absolute
        if expandedPath.hasPrefix("/") || expandedPath.hasPrefix("file://") {
            let url = URL(fileURLWithPath: expandedPath)
            return url.standardized
        }
        
        // Handle relative paths
        let baseURL = base ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = URL(fileURLWithPath: expandedPath, relativeTo: baseURL)
        return url.standardized
    }
}

// MARK: files
extension String {
    /// Find files in the directory pointed to by self with a suffix
    /// - Parameter suffix: suffix to be searched, which can be a file
    /// extension or more than that
    func findFiles(suffix: FileSuffix) -> [String]? {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: self)
            let matchingFiles = contents
                .filter { $0.hasSuffix(suffix.rawValue) }
                .map { (self as NSString).appendingPathComponent($0) }
            return matchingFiles
        } catch {
            return nil
        }
    }
    
    /// Extract sample ID from filename by removing a known suffix
    /// - Parameters:
    ///   - filename: The full filename (e.g., "sample123_processed.fastq")
    ///   - suffix: The suffix to remove (e.g., "_processed.fastq")
    /// - Returns: The sample ID (prefix before the suffix) but returns nil
    /// if the filename does not contain the required suffix or if the
    /// sampleID is empty
    func sampleID(suffix: FileSuffix) -> String? {
        guard self.hasSuffix(suffix.rawValue) else { return nil }
        let endIndex = self.index(self.endIndex, offsetBy: -suffix.rawValue.count)
        let sampleID = String(self[..<endIndex])
        guard sampleID.isEmpty == false else { return nil }
        return sampleID
    }
}

// MARK: Suffixes
enum FileSuffix: String {
    case blast = "_representative_blast.tsv"
    case main = "_classified.tsv"
    case representative = "_representative_classified.tsv"
    case report = "_merged_output.tsv"
    case hitcounts = "_hitcounts_output.tsv"
}

// MARK: Prefixes
enum FilePrefix: String {
    case blast = "blast"
}
