//
//  ReceiptReadAhead.swift
//  ExpenseKu
//
//  Reads waiting receipts before the owner opens them (docs/prd/receipt-reading.md
//  §4.11): a pass on each foreground, oldest first, one reading at a time through the
//  gate, stopped in the background because an iPhone gives a background app no GPU. A
//  form asking for a receipt joins the reading already under way, or goes next.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReceiptReadAhead {
    private(set) var readings: [String: StoredReceiptReading] = [:]
    private(set) var progress: ReadAheadProgress?

    @ObservationIgnored private let folder: ReceiptInboxFolder
    @ObservationIgnored private let gate = ReceiptReadGate()
    @ObservationIgnored private var inFlight: [String: Task<StoredReceiptReading?, Never>] = [:]
    @ObservationIgnored private var pass: Task<Void, Never>?
    @ObservationIgnored private var isActive = false

    init(folder: ReceiptInboxFolder = .shared) {
        self.folder = folder
    }

    func start(items: [ReceiptInboxItem], categories: [String], models: ReceiptModelStore) {
        isActive = true
        readings = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            (readings[item.id] ?? folder.storedReading(for: item)).map { (item.id, $0) }
        })
        guard pass == nil else { return }
        let toRead = ReadAheadPlan.receiptsToRead(items, stored: readings, modelIsReady: models.isModelReady)
        guard !toRead.isEmpty else { return }
        pass = Task {
            for (index, item) in toRead.enumerated() {
                guard !Task.isCancelled else { return }
                progress = ReadAheadProgress(position: index + 1, total: toRead.count)
                _ = await reading(for: item, categories: categories, models: models)
            }
            guard !Task.isCancelled else { return }
            progress = nil
            pass = nil
            if inFlight.isEmpty { models.unload() }
        }
    }

    func stop() {
        isActive = false
        pass?.cancel()
        pass = nil
        progress = nil
        inFlight.values.forEach { $0.cancel() }
        inFlight = [:]
    }

    /// The receipt's reading, read now if it has none; nil when the app left the
    /// foreground before it was read.
    func reading(for item: ReceiptInboxItem, categories: [String], models: ReceiptModelStore) async -> StoredReceiptReading? {
        if let stored = readings[item.id] ?? folder.storedReading(for: item),
           !ReadAheadPlan.needsReading(stored, modelIsReady: models.isModelReady) {
            readings[item.id] = stored
            return stored
        }
        guard isActive else { return nil }
        let task = inFlight[item.id] ?? read(item, categories: categories, models: models)
        return await task.value
    }

    /// A receipt from Photos, the camera or the clipboard: read in turn with the inbox,
    /// and not kept.
    func read(_ data: Data, categories: [String], models: ReceiptModelStore) async -> StoredReceiptReading {
        let reader = ReceiptReader(model: models.model)
        await gate.acquire()
        let reading = (try? await reader.reading(of: data, categories: categories))
            ?? StoredReceiptReading(reading: ReceiptReading(), hadModel: reader.model != nil)
        await gate.release()
        return reading
    }

    func forget(_ item: ReceiptInboxItem) {
        inFlight[item.id]?.cancel()
        inFlight[item.id] = nil
        readings[item.id] = nil
        folder.removeReading(for: item)
    }

    private func read(_ item: ReceiptInboxItem, categories: [String], models: ReceiptModelStore)
        -> Task<StoredReceiptReading?, Never> {
        let reader = ReceiptReader(model: models.model)
        let gate = gate
        let task = Task<StoredReceiptReading?, Never> {
            await gate.acquire()
            guard !Task.isCancelled else {
                await gate.release()
                return nil
            }
            let data = try? Data(contentsOf: item.url)
            let read = if let data { try? await reader.reading(of: data, categories: categories) } else { StoredReceiptReading?.none }
            let reading = read ?? StoredReceiptReading(reading: ReceiptReading(), hadModel: reader.model != nil)
            await gate.release()
            guard !Task.isCancelled else { return nil }
            folder.store(reading, for: item)
            readings[item.id] = reading
            inFlight[item.id] = nil
            return reading
        }
        inFlight[item.id] = task
        return task
    }
}
