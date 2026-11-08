//
//  ModelFile.swift
//  ExpenseKu
//
//  One file of the model repository on Hugging Face, as its tree listing names it.
//

import Foundation

nonisolated struct ModelFile: Decodable, Sendable, Hashable {
    let type: String
    let path: String
    let size: Int64
}
