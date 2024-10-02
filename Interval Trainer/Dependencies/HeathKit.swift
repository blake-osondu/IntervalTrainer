//
//  HeathKitManager.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/28/24.
//

import Foundation
import HealthKit
import Dependencies


public struct HealthKitClient {
    var startWorkout: @Sendable () throws -> HKWorkoutSession?
    var endWorkout: @Sendable (HKWorkoutSession) async -> Double
    var getActiveEnergyBurned: @Sendable (Date, Date) async ->  Double
}

extension HealthKitClient: DependencyKey {
    static public let liveValue: HealthKitClient = Self(
        startWorkout: {
            #if os(watchOS)
                let session = try? HealthKitManager.shared.startWorkout()
                return session
            #endif
                return nil
        }, endWorkout: { session in
            #if os(watchOS)
                let calories = await HealthKitManager.shared.endWorkout(session)
                return calories
            #endif
            return 0
        }, getActiveEnergyBurned: { start, end in
            let calories = await HealthKitManager.shared.getActiveEnergyBurned(start: start, end: end)
            return calories
        }
    )
    
}

extension HealthKitClient: TestDependencyKey {
    static public let testValue: HealthKitClient = Self(
        startWorkout: {
            return nil
        }, endWorkout: { session in
            return 249
        }, getActiveEnergyBurned: {start, end in
            return 1034
        }
    )
}

extension DependencyValues {
    public var healthKitClient: HealthKitClient {
        get { self[HealthKitClient.self] }
        set { self[HealthKitClient.self] = newValue }
    }
}

public class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let energyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        
        healthStore.requestAuthorization(toShare: [energyBurnedType], read: [energyBurnedType]) { success, error in
            completion(success, error)
        }
    }
    
    #if os(watchOS)
    func startWorkout() -> HKWorkoutSession? {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            try session.startActivity(with: Date())
            return session
        } catch {
            print("Failed to start workout session: \(error.localizedDescription)")
            return nil
        }
    }
    
    func endWorkout(_ session: HKWorkoutSession) async -> Double {
        session.end()
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: session.startDate, end: Date(), options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(with: .success(0.0))
                    return
                }
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(with: .success(calories))
            }
            healthStore.execute(query)
        }
    }
    #endif
    
    func getActiveEnergyBurned(start: Date, end: Date) async -> Double {
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(with: .success(0.0))
                    return
                }
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(with: .success(calories))
            }
            healthStore.execute(query)
        }
    }
}
