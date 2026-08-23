//
//  CompanionNames.swift
//  ExpenseKu
//
//  How an expense's companions are read back as one phrase: "Tarisa",
//  "Tarisa and Fadil", "Anas, Beni, and Me". Alphabetical, Oxford comma from three.
//

import Foundation

nonisolated enum CompanionNames {
    static func phrase(_ people: [Person]?) -> String {
        phrase(names: (people ?? []).map(\.name))
    }

    static func phrase(names: [String]) -> String {
        let sorted = names.sorted()
        switch sorted.count {
        case 0:
            return ""
        case 1:
            return sorted[0]
        case 2:
            return "\(sorted[0]) and \(sorted[1])"
        default:
            guard let last = sorted.last else { return "" }
            return sorted.dropLast().joined(separator: ", ") + ", and " + last
        }
    }
}
