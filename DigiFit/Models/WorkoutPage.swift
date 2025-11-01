import Foundation

struct WorkoutPage: Identifiable {
    let id = UUID()
    var name: String
    var exercises: [Exercise]
}