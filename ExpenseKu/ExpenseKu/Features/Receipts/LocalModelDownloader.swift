//
//  LocalModelDownloader.swift
//  ExpenseKu
//
//  MLX's loader asks for a downloader even when the configuration names a folder; it
//  never calls it then. Downloading is ReceiptModelStore's job, with its own progress and
//  resume, so this one refuses.
//

#if canImport(MLXVLM)
import Foundation
import MLXLMCommon

nonisolated struct LocalModelDownloader: MLXLMCommon.Downloader {
    func download(id: String, revision: String?, matching patterns: [String], useLatest: Bool,
                  progressHandler: @Sendable @escaping (Progress) -> Void) async throws -> URL {
        throw URLError(.fileDoesNotExist)
    }
}
#endif
