import Foundation

struct WorkoutSession: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let weight: Double
    let reps: Int
}

struct Exercise: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var sets: Int?
    var reps: Int?
    var workoutHistory: [WorkoutSession] = []
}