//
//  HealthKitManager.swift
//  HydraTrack
//

import Foundation
import Combine
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized: Bool = false
    @Published var sleepSchedule: (wake: Date, sleep: Date)?

    // MARK: - Authorization

    func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthKitAvailable() else {
            throw HealthKitError.notAvailable
        }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set<HKObjectType> = [sleepType]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        await MainActor.run {
            isAuthorized = true
        }
    }

    // MARK: - Sleep Schedule

    func fetchSleepSchedule() async throws -> (wake: Date, sleep: Date)? {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }

                guard !asleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                var wakeHours: [Int] = []
                var sleepHours: [Int] = []

                for sample in asleepSamples {
                    let wakeHour = Calendar.current.component(.hour, from: sample.endDate)
                    let wakeMinute = Calendar.current.component(.minute, from: sample.endDate)
                    wakeHours.append(wakeHour * 60 + wakeMinute)

                    let sleepHour = Calendar.current.component(.hour, from: sample.startDate)
                    let sleepMinute = Calendar.current.component(.minute, from: sample.startDate)
                    sleepHours.append(sleepHour * 60 + sleepMinute)
                }

                guard !wakeHours.isEmpty, !sleepHours.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let avgWakeMinutes = wakeHours.reduce(0, +) / wakeHours.count
                let avgSleepMinutes = sleepHours.reduce(0, +) / sleepHours.count

                let wakeTime = Calendar.current.date(bySettingHour: avgWakeMinutes / 60, minute: avgWakeMinutes % 60, second: 0, of: Date()) ?? Date()
                let sleepTime = Calendar.current.date(bySettingHour: avgSleepMinutes / 60, minute: avgSleepMinutes % 60, second: 0, of: Date()) ?? Date()

                continuation.resume(returning: (wakeTime, sleepTime))
            }

            self.healthStore.execute(query)
        }
    }
}

enum HealthKitError: Error {
    case notAvailable
    case notAuthorized
}
