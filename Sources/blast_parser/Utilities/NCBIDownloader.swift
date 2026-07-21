//
//  NCBIDownloader.swift
//  blast_parser
//
//  Created by João Varela on 02/07/2026.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Foundation
import ArgumentParser

// MARK: - Cross-Platform Downloader Utility
enum NCBIDownloader {

    /// Basic wrapper to fetch small data (like the MD5 file) on both platforms.
    static func fetchData(from url: URL) async throws -> Data {
        #if os(macOS)
        let session = URLSession(configuration: .ephemeral)
        let (data, _) = try await session.data(from: url)
        return data
        #else
        return try await LinuxDataTaskRunner.shared.run(url: url)
        #endif
    }

    /// Downloads larger payloads while printing a live progress bar.
    static func fetchDataWithProgress(from url: URL) async throws -> Data {
        #if os(macOS)
        return try await _fetchWithProgressMacOS(from: url)
        #else
        return try await LinuxProgressDownloader.shared.download(url: url)
        #endif
    }
}

// MARK: - macOS implementation (URLSessionDownloadTask + delegate)

#if os(macOS)
private extension NCBIDownloader {
    static func _fetchWithProgressMacOS(from url: URL) async throws -> Data {
        let delegate = MacOSDownloadDelegate()
        let session  = URLSession(configuration: .ephemeral,
                                  delegate: delegate,
                                  delegateQueue: nil)
        return try await withCheckedThrowingContinuation { continuation in
            delegate.onComplete = { result in
                session.invalidateAndCancel()
                continuation.resume(with: result)
            }
            session.downloadTask(with: url).resume()
        }
    }
}

final class MacOSDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    var onComplete: ((Result<Data, Error>) -> Void)?
    private var hasPrintedHeader = false

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        if !hasPrintedHeader && totalBytesExpectedToWrite > 0 {
            print("Downloading new_taxdump tar file:")
            hasPrintedHeader = true
        }
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            Utilities.drawProgressBar(
                progress: progress,
                current:  Int(totalBytesWritten),
                total:    totalBytesExpectedToWrite
            )
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        Utilities.finishProgressBar()
        do {
            let data = try Data(contentsOf: location)
            onComplete?(.success(data))
        } catch {
            onComplete?(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Utilities.finishProgressBar()
            onComplete?(.failure(error))
        }
    }
}
#endif

// MARK: - Linux implementation
//
// swift-corelibs-foundation on Linux has a known bug: creating and destroying
// multiple URLSession instances rapidly corrupts the shared libcurl
// _MultiHandle pool, causing an abort with:
//   "Object … of class _MultiHandle deallocated with non-zero retain count"
//
// The only reliable fix is to NEVER destroy a URLSession on Linux.
// We use two singletons — one for plain data tasks, one for progress downloads
// — that live for the entire process lifetime.

#if !os(macOS)

// MARK: Plain data task singleton (used by fetchData)
final class LinuxDataTaskRunner: NSObject, URLSessionDataDelegate, @unchecked Sendable {

    static let shared = LinuxDataTaskRunner()

    // Session created once, never invalidated.
    private lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )

    // Per-task state keyed by task identifier.
    private var lock = NSLock()
    private var buffers: [Int: Data] = [:]
    private var continuations: [Int: CheckedContinuation<Data, Error>] = [:]

    private override init() { super.init() }

    func run(url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: url)
            lock.lock()
            buffers[task.taskIdentifier] = Data()
            continuations[task.taskIdentifier] = continuation
            lock.unlock()
            task.resume()
        }
    }

    // MARK: URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        buffers[dataTask.taskIdentifier]?.append(data)
        lock.unlock()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        let cont = continuations.removeValue(forKey: task.taskIdentifier)
        let buffer = buffers.removeValue(forKey: task.taskIdentifier)
        lock.unlock()

        if let error = error {
            cont?.resume(throwing: error)
        } else {
            cont?.resume(returning: buffer ?? Data())
        }
    }
}

// MARK: Progress download singleton (used by fetchDataWithProgress)
final class LinuxProgressDownloader: NSObject, URLSessionDataDelegate, @unchecked Sendable {

    static let shared = LinuxProgressDownloader()

    // Session created once, never invalidated.
    private lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )

    private struct TaskState {
        var buffer:         Data
        var expectedLength: Int64
        var headerPrinted:  Bool
        var continuation:   CheckedContinuation<Data, Error>
    }

    private var lock  = NSLock()
    private var tasks: [Int: TaskState] = [:]

    private override init() { super.init() }

    func download(url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: url)
            lock.lock()
            tasks[task.taskIdentifier] = TaskState(
                buffer:         Data(),
                expectedLength: 0,
                headerPrinted:  false,
                continuation:   continuation
            )
            lock.unlock()
            task.resume()
        }
    }

    // MARK: URLSessionDataDelegate

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let http = response as? HTTPURLResponse else {
            completionHandler(.allow)
            return
        }
        guard (200...299).contains(http.statusCode) else {
            lock.lock()
            let cont = tasks.removeValue(forKey: dataTask.taskIdentifier)?.continuation
            lock.unlock()
            cont?.resume(throwing: ValidationError(
                "NCBI server returned status code: \(http.statusCode)"
            ))
            completionHandler(.cancel)
            return
        }
        lock.lock()
        tasks[dataTask.taskIdentifier]?.expectedLength = http.expectedContentLength
        if http.expectedContentLength > 0 {
            tasks[dataTask.taskIdentifier]?.buffer
                .reserveCapacity(Int(http.expectedContentLength))
        }
        lock.unlock()
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        tasks[dataTask.taskIdentifier]?.buffer.append(data)
        let state = tasks[dataTask.taskIdentifier]
        lock.unlock()

        guard let state else { return }
        if state.expectedLength > 0 {
            if !state.headerPrinted {
                print("Downloading new_taxdump tar file:")
                lock.lock()
                tasks[dataTask.taskIdentifier]?.headerPrinted = true
                lock.unlock()
            }
            let progress = Double(state.buffer.count) / Double(state.expectedLength)
            Utilities.drawProgressBar(
                progress: progress,
                current:  state.buffer.count,
                total:    state.expectedLength
            )
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Utilities.finishProgressBar()
        lock.lock()
        let state = tasks.removeValue(forKey: task.taskIdentifier)
        lock.unlock()

        if let error = error {
            state?.continuation.resume(throwing: error)
        } else {
            state?.continuation.resume(returning: state?.buffer ?? Data())
        }
    }
}
#endif
