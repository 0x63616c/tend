import Foundation
import HealthKit

enum HealthKitWeightStore {
    private static let store = HKHealthStore()
    private static var bodyMass: HKQuantityType? { HKQuantityType.quantityType(forIdentifier: .bodyMass) }

    static func requestAndFetch() async throws -> [WeightEntry] {
        guard HKHealthStore.isHealthDataAvailable(), let bodyMass else { return [] }
        try await store.requestAuthorization(toShare: [], read: [bodyMass])
        return try await fetch(bodyMass)
    }

    static func fetch() async throws -> [WeightEntry] {
        guard HKHealthStore.isHealthDataAvailable(), let bodyMass else { return [] }
        return try await fetch(bodyMass)
    }

    private static func fetch(_ type: HKQuantityType) async throws -> [WeightEntry] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let weights = (samples as? [HKQuantitySample] ?? []).map {
                    WeightEntry(
                        date: $0.startDate,
                        kilograms: $0.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                        healthKitID: $0.uuid,
                        sourceName: $0.sourceRevision.source.name
                    )
                }
                continuation.resume(returning: weights)
            }
            store.execute(query)
        }
    }
}
