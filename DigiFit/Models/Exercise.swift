import Foundation

struct Exercise: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var sets: Int
    var reps: Int
}