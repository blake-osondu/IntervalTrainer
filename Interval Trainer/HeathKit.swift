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
    var startWorkout: @Sendable () async throws ->  HKWorkoutSession?
    var endWorkout: @Sendable (HKWorkoutSession, (Double) async -> Void) async ->  Void
    var getActiveEnergyBurned: @Sendable (Date, Date, @escaping (Double) async -> Void) ->  Void
}

extension HealthKitClient: DependencyKey {
    static public let liveValue: HealthKitClient = Self(
        startWorkout: {
            #if os(watchOS)
                return try? await HealthKitManager.shared.startWorkout()
            #endif
                return nil
        }, endWorkout: { session, completion in
            #if os(watchOS)
                await HealthKitManager.shared.endWorkout(session, completion)
            #endif
        }, getActiveEnergyBurned: {start, end, completion in
            return HealthKitManager.shared.getActiveEnergyBurned(start: start, end: end, completion: completion)
        }
    )
    
}

extension HealthKitClient: TestDependencyKey {
    static public let testValue: HealthKitClient = Self(
        startWorkout: {
            return nil
        }, endWorkout: { session, completion in
            
        }, getActiveEnergyBurned: {start, end, completion in
            
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
    
    func endWorkout(_ session: HKWorkoutSession, completion: @escaping (Double) async -> Void) {
        session.end()
        
        let predicate = HKQuery.predicateForSamples(withStart: session.startDate, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else {
                Task.init {
                    await completion(0.0)
                }
                return
            }
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            Task.init {
                await completion(calories)
            }
        }
        healthStore.execute(query)
    }
    #endif
    
    func getActiveEnergyBurned(start: Date, end: Date, completion: @escaping (Double) async -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else {
                Task.init {
                    await completion(0.0)
                }
                return
            }
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            Task.init {
                await completion(calories)
            }
        }
        healthStore.execute(query)
    }
}
