//
//  GemmaTokenizerLoader.swift
//  ExpenseKu
//
//  Loads the tokenizer from the downloaded model folder.
//

#if canImport(MLXLLM)
import Foundation
import MLXLMCommon
import Tokenizers

nonisolated struct GemmaTokenizerLoader: MLXLMCommon.TokenizerLoader {
    func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        GemmaTokenizerBridge(try await Tokenizers.AutoTokenizer.from(modelFolder: directory))
    }
}
#endif
