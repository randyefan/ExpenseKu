//
//  GemmaReceiptModel.swift
//  ExpenseKu
//
//  Gemma 4 E2B through MLX Swift, loaded from the downloaded folder on its first answer
//  and kept until the store lets it go. Greedy decoding with thinking off and a short
//  token budget: the answer is one small JSON object, and Gemma ends its turn with
//  "<turn|>", which the tokenizer does not list as an end token (found in the spike).
//

import CoreImage
import Foundation
#if canImport(MLXVLM)
import MLX
import MLXVLM
import MLXLMCommon
#endif

nonisolated final class GemmaReceiptModel: ReceiptModel {
    #if canImport(MLXVLM)
    static let isAvailable = true

    private let loader: Loader

    init(directory: URL) {
        loader = Loader(directory: directory)
    }

    func answer(_ prompt: String, image: Data) async throws -> String {
        guard let receipt = CIImage(data: image, options: [.applyOrientationProperty: true]) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        Memory.cacheLimit = 20 * 1024 * 1024
        let container = try await loader.container()
        let session = ChatSession(
            container,
            instructions: ExtractionPrompt.systemInstructions,
            generateParameters: GenerateParameters(maxTokens: 200, temperature: 0),
            additionalContext: ["enable_thinking": false]
        )
        return try await session.respond(to: prompt, image: .ciImage(receipt))
    }

    private actor Loader {
        let directory: URL
        private var loaded: ModelContainer?

        init(directory: URL) { self.directory = directory }

        func container() async throws -> ModelContainer {
            if let loaded { return loaded }
            let configuration = ModelConfiguration(directory: directory, extraEOSTokens: ["<turn|>"])
            let container = try await VLMModelFactory.shared.loadContainer(
                from: LocalModelDownloader(), using: GemmaTokenizerLoader(), configuration: configuration)
            loaded = container
            return container
        }
    }
    #else
    static let isAvailable = false

    init(directory: URL) {}

    func answer(_ prompt: String, image: Data) async throws -> String { "" }
    #endif
}
