//
//  ModelFileDownload.swift
//  ExpenseKu
//
//  One file of the model, downloaded with byte progress and resumable: cancelling keeps
//  URLSession's resume data so a broken or paused download picks up where it stopped
//  (docs/prd/receipt-reading.md §4.10).
//

import Foundation

nonisolated final class ModelFileDownload: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<URL, any Error>?
    private var task: URLSessionDownloadTask?
    private let destination: URL
    private let onBytes: @Sendable (Int64) -> Void
    private(set) var resumeData: Data?

    init(destination: URL, onBytes: @escaping @Sendable (Int64) -> Void) {
        self.destination = destination
        self.onBytes = onBytes
    }

    func run(from url: URL, resumingFrom resumeData: Data?, allowsCellular: Bool) async throws -> URL {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = allowsCellular
        configuration.allowsExpensiveNetworkAccess = allowsCellular
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        return try await withCheckedThrowingContinuation { continuation in
            lock.withLock {
                self.continuation = continuation
                let task = resumeData.map(session.downloadTask(withResumeData:)) ?? session.downloadTask(with: url)
                self.task = task
                task.resume()
            }
        }
    }

    func pause() {
        let task = lock.withLock { self.task }
        task?.cancel { [weak self] data in
            self?.lock.withLock { self?.resumeData = data }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        onBytes(totalBytesWritten)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
            finish(.success(destination))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard let error else { return }
        let data = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        lock.withLock { if let data { resumeData = data } }
        finish(.failure(error))
    }

    private func finish(_ result: Result<URL, any Error>) {
        let continuation = lock.withLock {
            defer { self.continuation = nil }
            return self.continuation
        }
        continuation?.resume(with: result)
    }
}
