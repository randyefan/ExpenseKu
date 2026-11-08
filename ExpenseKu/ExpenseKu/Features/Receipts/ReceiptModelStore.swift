//
//  ReceiptModelStore.swift
//  ExpenseKu
//
//  Gemma 4 E2B on this iPhone (docs/prd/receipt-reading.md §4.10): downloaded from
//  Hugging Face on request, one file at a time and resumable, kept in Application Support
//  out of backups, removed on request. Loaded into memory on the first reading and
//  released when the app goes to the background.
//

import Foundation
import Network
import Observation

@MainActor
@Observable
final class ReceiptModelStore {
    static let repository = "mlx-community/gemma-4-e2b-it-4bit"
    static let expectedBytes: Int64 = 3_600_000_000

    private(set) var phase: ReceiptModelPhase = .notDownloaded
    private(set) var isOnCellular = false

    @ObservationIgnored private let directory: URL
    @ObservationIgnored private var download: ModelFileDownload?
    @ObservationIgnored private var downloadTask: Task<Void, Never>?
    @ObservationIgnored private var resumeData: [String: Data] = [:]
    @ObservationIgnored private var loaded: (any ReceiptModel)?
    @ObservationIgnored private let pathMonitor = NWPathMonitor()

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "ReceiptModel", directoryHint: .isDirectory)) {
        self.directory = directory
        if FileManager.default.fileExists(atPath: completeMarker.path(percentEncoded: false)) {
            phase = .ready
            excludeFromBackup()
        } else if let received = try? downloadedBytes(), received > 0 {
            phase = .paused(received: received, total: Self.expectedBytes, error: nil)
        }
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let cellular = path.usesInterfaceType(.cellular) && !path.usesInterfaceType(.wifi)
            Task { @MainActor in self?.isOnCellular = cellular }
        }
        pathMonitor.start(queue: .global(qos: .utility))
    }

    private var completeMarker: URL { directory.appending(path: ".complete") }

    private func excludeFromBackup() {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var folder = directory
        try? folder.setResourceValues(values)
    }

    /// The model to read with, when it is downloaded and this device can run it.
    var model: (any ReceiptModel)? {
        guard phase == .ready, ReceiptModelRuntime.canRun else { return nil }
        if loaded == nil { loaded = ReceiptModelRuntime.make(directory: directory) }
        return loaded
    }

    func unload() {
        loaded = nil
    }

    func download(allowingCellular: Bool) {
        guard downloadTask == nil else { return }
        downloadTask = Task { [weak self] in
            await self?.runDownload(allowingCellular: allowingCellular)
            self?.downloadTask = nil
        }
    }

    func pause() {
        download?.pause()
    }

    func remove() {
        download?.pause()
        downloadTask?.cancel()
        downloadTask = nil
        loaded = nil
        resumeData = [:]
        try? FileManager.default.removeItem(at: directory)
        phase = .notDownloaded
    }

    private func runDownload(allowingCellular: Bool) async {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            excludeFromBackup()

            let files = try await listing()
            let total = files.reduce(0) { $0 + $1.size }
            var done: Int64 = files.filter(isComplete).reduce(0) { $0 + $1.size }
            phase = .downloading(received: done, total: total)

            for file in files where !isComplete(file) {
                let destination = directory.appending(path: file.path)
                let before = done
                let download = ModelFileDownload(destination: destination) { [weak self] written in
                    Task { @MainActor in self?.phase = .downloading(received: before + written, total: total) }
                }
                self.download = download
                let source = URL(string: "https://huggingface.co/\(Self.repository)/resolve/main/\(file.path)")
                guard let source else { continue }
                do {
                    _ = try await download.run(from: source, resumingFrom: resumeData[file.path],
                                               allowsCellular: allowingCellular)
                    resumeData[file.path] = nil
                    done += file.size
                } catch {
                    resumeData[file.path] = download.resumeData
                    let cancelled = (error as? URLError)?.code == .cancelled
                    let received = if case .downloading(let received, _) = phase { received } else { done }
                    phase = .paused(received: received, total: total, error: cancelled ? nil : error.localizedDescription)
                    self.download = nil
                    return
                }
            }
            self.download = nil
            FileManager.default.createFile(atPath: completeMarker.path(percentEncoded: false), contents: nil)
            phase = .ready
        } catch {
            phase = .paused(received: (try? downloadedBytes()) ?? 0, total: Self.expectedBytes,
                            error: error.localizedDescription)
        }
    }

    private func listing() async throws -> [ModelFile] {
        guard let url = URL(string: "https://huggingface.co/api/models/\(Self.repository)/tree/main?recursive=1") else {
            return []
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ModelFile].self, from: data).filter { $0.type == "file" }
    }

    private func isComplete(_ file: ModelFile) -> Bool {
        let path = directory.appending(path: file.path).path(percentEncoded: false)
        let size = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64) ?? nil
        return size == file.size
    }

    private func downloadedBytes() throws -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }
}
