import Foundation
import CloudKit
import Dependencies

struct CloudKitClient {
    var saveWorkoutPlan: @Sendable (WorkoutPlan) async throws -> Void
    var fetchWorkoutPlans: @Sendable () async -> [WorkoutPlan]
    var saveCompletedWorkout: @Sendable (CompletedWorkout) async throws -> Void
    var fetchCompletedWorkouts: @Sendable () async -> [CompletedWorkout]
}

extension CloudKitClient: DependencyKey {
    static let liveValue: CloudKitClient = Self(
        saveWorkoutPlan: { workoutPlan in
            try await CloudKitManager.shared.saveWorkoutPlan(workoutPlan)
    }, fetchWorkoutPlans: {
            let plans = (try? await CloudKitManager.shared.fetchWorkoutPlans()) ?? []
            return generateSamplePlans() + plans
    }, saveCompletedWorkout: { workout in
        try await CloudKitManager.shared.saveCompletedWorkout(workout)
    }, fetchCompletedWorkouts: {
        do {
            let workouts = try await CloudKitManager.shared.fetchCompletedWorkouts()
            return workouts
        } catch {
            return []
        }
    })
}

extension CloudKitClient: TestDependencyKey {
    static let testValue: CloudKitClient = Self(
        saveWorkoutPlan: { _ in
            return
    }, fetchWorkoutPlans: {
        generateSamplePlans()
    }, saveCompletedWorkout: { _ in
        return
    }, fetchCompletedWorkouts: {
        generateSampleWorkouts()
    })
}

extension DependencyValues {
    var cloudKitClient: CloudKitClient {
        get { self[CloudKitClient.self] }
        set { self[CloudKitClient.self] = newValue }
    }
}

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    
    private init() {
        container = CKContainer.init(identifier: "iCloud.com.kinnectus.intervaltrainer.icloudcontainer")
        publicDatabase = container.publicCloudDatabase
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Workout Plans
    
    func saveWorkoutPlan(_ workoutPlan: WorkoutPlan) async throws {
        let record = try workoutPlan.cloudKitRecord()
        try await privateDatabase.save(record)
    }
    
    func fetchWorkoutPlans() async throws -> [WorkoutPlan] {
        let query = CKQuery(recordType: "WorkoutPlan", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        return try matchResults.compactMap { _, result in
            try WorkoutPlan(from: result.get())
        }
    }
        
 
    // MARK: - Completed Workouts
    
    func saveCompletedWorkout(_ workout: CompletedWorkout) async throws {
        let record = try workout.cloudKitRecord()
        try await privateDatabase.save(record)
    }
    
    func fetchCompletedWorkouts() async throws -> [CompletedWorkout] {
        let query = CKQuery(recordType: "CompletedWorkout", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        return try matchResults.compactMap { _, result in
            try CompletedWorkout(from: result.get())
        }
    }
}
// MARK: - CloudKit Convertible

protocol CloudKitConvertible {
    func cloudKitRecord() throws -> CKRecord
    init(from record: CKRecord) throws
}

extension WorkoutPlan: CloudKitConvertible {
    func cloudKitRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "WorkoutPlan")
        record["id"] = id.uuidString
        record["name"] = name
        record["intervals"] = try JSONEncoder().encode(intervals)
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let intervalsData = record["intervals"] as? Data,
              let intervals = try? JSONDecoder().decode([Interval].self, from: intervalsData) else {
            throw NSError(domain: "WorkoutPlanError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid record data"])
        }
        self.id = id
        self.name = name
        self.intervals = intervals
    }
}

extension CompletedWorkout: CloudKitConvertible {
    
    func cloudKitRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "CompletedWorkout")
        record["id"] = id.uuidString
        record["name"] = name
        record["date"] = date
        record["duration"] = duration
        record["caloriesBurned"] = caloriesBurned
        record["rating"] = rating
        return record
    }
    
    init(from record: CKRecord) throws {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let date = record["date"] as? Date,
              let duration = record["duration"] as? TimeInterval,
              let caloriesBurned = record["caloriesBurned"] as? Double,
              let rating = record["rating"] as? Int else {
            throw NSError(domain: "CompletedWorkoutError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid record data"])
        }
        self.id = id
        self.name = name
        self.date = date
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.rating = rating
    }
}

extension CloudKitClient {
    private static func generateSampleWorkouts() -> [CompletedWorkout] {
        let calendar = Calendar.current
        let now = Date()
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
        
        var workouts: [CompletedWorkout] = []
        var currentDate = threeMonthsAgo
        
        while currentDate <= now {
            let workoutsThisWeek = Int.random(in: 0...5)  // 0 to 5 workouts per week
            
            for _ in 0..<workoutsThisWeek {
                let workoutDate = calendar.date(byAdding: .hour, value: Int.random(in: 0...23), to: currentDate)!
                let workout = CompletedWorkout(
                    id: UUID(),
                    name: randomWorkoutName(),
                    date: workoutDate,
                    // 15 to 120 minutes
                    duration: TimeInterval(Int.random(in: 15...120) * 60),
                    caloriesBurned: Double.random(in: 100...500),
                    rating: 5
                )
                workouts.append(workout)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)!
        }
        
        return workouts
    }
    
    private static func generateSamplePlans() -> [WorkoutPlan] {
        [
            WorkoutPlan(id: UUID(), name: "HIIT Cardio", intervals: [
                    Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300),
                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 50),
                    Interval(id: UUID(), name: "Low Intensity", type: .highIntensity, duration: 10),
                    Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                ]),
            WorkoutPlan(id: UUID(), name: "Strength Training", intervals: [
                    Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300),
                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 50),
                    Interval(id: UUID(), name: "Low Intensity", type: .highIntensity, duration: 10),
                    Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                ])
        ]
    }
    
    private static func randomWorkoutName() -> String {
        let workoutTypes = ["Run", "Yoga", "HIIT", "Strength Training", "Cycling", "Swimming", "Pilates", "Boxing"]
        let modifiers = ["Morning", "Evening", "Intense", "Relaxing", "Quick", "Extended"]
        
        let type = workoutTypes.randomElement()!
        let modifier = modifiers.randomElement()!
        
        return "\(modifier) \(type)"
    }
   
}
