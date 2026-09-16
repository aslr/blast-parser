//
//  Utilities.swift
//  blast-parser
//
//  Created by João Varela on 29/05/2026.
//

import Foundation

struct Utilities {
    // MARK: - Shell Process Execution Helper
    public static func executeTarCommand(archiveURL: URL, targetDirectory: URL) throws {
        let process = Process()
        
        // Standard Linux & macOS absolute pathing to tar binary execution environment
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        if !FileManager.default.fileExists(atPath: process.executableURL!.path) {
            process.executableURL = URL(fileURLWithPath: "/bin/tar") // Linux alternate path fallback
        }
        
        // Arguments: -x (extract), -z (gzip filtering), -f (file path target), -C (target directory)
        process.arguments = ["-xzf", archiveURL.path, "-C", targetDirectory.path]
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw NSError(
                domain: "TarExtractionError",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "System process failed to extract the tar archive safely."]
            )
        }
    }

    // MARK: - CLI Graphics Helpers

    /// Redraws the progress bar on the **same** terminal line on every call.
    ///
    /// The string is prefixed with \r (carriage-return, no newline) and written
    /// via `Console.writeToStdOutInPlace`, which does NOT append \n and flushes
    /// stdout immediately — fixing the "new line per tick" bug on macOS and the
    /// invisible-bar bug on Linux.
    public static func drawProgressBar(progress: Double, current: Int, total: Int64) {
        let barWidth   = 30
        let clamped    = max(0.0, min(1.0, progress))
        let percentage = Int(clamped * 100)
        let filledWidth = Int(clamped * Double(barWidth))
        let emptyWidth  = max(0, barWidth - filledWidth)
        
        let filledBar = String(repeating: "█", count: filledWidth)
        let emptyBar  = String(repeating: "░", count: emptyWidth)
        
        let currentMB = Double(current) / 1_048_576
        let totalMB   = Double(total)   / 1_048_576
        
        // \r at the front, NO \n at the back — cursor returns to column 0
        // and the next call overwrites the same line.
        let output = String(
            format: "\r[%@%@] %3d%%  (%.2f / %.2f MB)",
            filledBar, emptyBar, percentage, currentMB, totalMB
        )
        Console.writeToStdOutInPlace(output)
    }

    /// Call once after the last `drawProgressBar` to advance to the next line.
    public static func finishProgressBar() {
        Console.writeToStdOut("")   // writes "" + \n → clean newline
    }
}
