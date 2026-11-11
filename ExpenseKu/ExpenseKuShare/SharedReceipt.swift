//
//  SharedReceipt.swift
//  ExpenseKuShare
//
//  The receipt another app shared: the first image or PDF among the attachments. Banking
//  apps hand over a file, raw image data, or only a UIImage object, so each is tried.
//

import UIKit
import UniformTypeIdentifiers

enum SharedReceipt {
    struct Payload {
        let data: Data
        let fileExtension: String
    }

    static func load(from items: [NSExtensionItem]) async -> Payload? {
        let providers = items.flatMap { $0.attachments ?? [] }
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier),
               let data = try? await provider.loadDataRepresentation(for: .pdf) {
                return Payload(data: data, fileExtension: "pdf")
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                if let data = try? await provider.loadDataRepresentation(for: .image), UIImage(data: data) != nil {
                    return Payload(data: data, fileExtension: provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) ? "png" : "jpg")
                }
                if let image = try? await provider.loadObject(ofClass: UIImage.self), let data = image.pngData() {
                    return Payload(data: data, fileExtension: "png")
                }
                if let data = await provider.loadImageItemAsPNG() {
                    return Payload(data: data, fileExtension: "png")
                }
            }
        }
        return nil
    }
}

private extension NSItemProvider {
    func loadImageItemAsPNG() async -> Data? {
        await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                continuation.resume(returning: (item as? UIImage)?.pngData())
            }
        }
    }

    func loadDataRepresentation(for type: UTType) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadDataRepresentation(for: type) { data, error in
                if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: error ?? CocoaError(.fileReadUnknown)) }
            }
        }
    }

    func loadObject<T: NSItemProviderReading & Sendable>(ofClass type: T.Type) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadObject(ofClass: type) { object, error in
                if let object = object as? T { continuation.resume(returning: object) }
                else { continuation.resume(throwing: error ?? CocoaError(.fileReadUnknown)) }
            }
        }
    }
}
