import Foundation

// MARK: - Profile Model

struct Profile: Codable, Identifiable {
    let id: String  // UUID from backend
    var name: String
    var email: String?
    var height: Double?
    var weight: Double?
    var heightUnit: String?
    var weightUnit: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, email, height, weight
        case heightUnit = "height_unit"
        case weightUnit = "weight_unit"
        case createdAt = "created_at"
    }
}

// MARK: - Workout Split Model

struct WorkoutSplit: Codable, Identifiable {
    let id: Int
    var name: String
    var active: Bool
    var exercises: [Exercise]?

    enum CodingKeys: String, CodingKey {
        case id, name, active, exercises
    }
}

// MARK: - Exercise Model

struct Exercise: Codable, Identifiable, Hashable {
    let id: Int
    var name: String
    var sets: Int
    var orderIndex: Int?
    var entries: [WorkoutEntry]?

    enum CodingKeys: String, CodingKey {
        case id, name, sets, entries
        case orderIndex = "order_index"
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Workout Entry Model

struct WorkoutEntry: Codable, Identifiable, Hashable {
    let id: Int
    var date: Date
    var weight: Double
    var reps: Int

    enum CodingKeys: String, CodingKey {
        case id, date, weight, reps
    }

    // Custom date decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        weight = try container.decode(Double.self, forKey: .weight)
        reps = try container.decode(Int.self, forKey: .reps)

        // Try to decode date as ISO8601 or as a simple date string
        let dateString = try container.decode(String.self, forKey: .date)

        if let date = ISO8601DateFormatter().date(from: dateString) {
            self.date = date
        } else {
            // Try simple date format (yyyy-MM-dd)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                self.date = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .date,
                    in: container,
                    debugDescription: "Date string does not match expected format"
                )
            }
        }
    }

    init(id: Int, date: Date, weight: Double, reps: Int) {
        self.id = id
        self.date = date
        self.weight = weight
        self.reps = reps
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WorkoutEntry, rhs: WorkoutEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Workout Session (for UI purposes)

struct WorkoutSession: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let weight: Double
    let reps: Int
    let entryId: Int?  // Link to backend entry

    init(date: Date, weight: Double, reps: Int, entryId: Int? = nil) {
        self.date = date
        self.weight = weight
        self.reps = reps
        self.entryId = entryId
    }

    // Create from WorkoutEntry
    init(from entry: WorkoutEntry) {
        self.date = entry.date
        self.weight = entry.weight
        self.reps = entry.reps
        self.entryId = entry.id
    }
}

// MARK: - UI Models for LandingPageView

// Local UI Exercise model for workout tracking interface
struct UIExercise: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var sets: Int?
    var reps: Int?
    var workoutHistory: [WorkoutSession] = []
    
    init(name: String, sets: Int?, reps: Int?) {
        self.name = name
        self.sets = sets
        self.reps = reps
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UIExercise, rhs: UIExercise) -> Bool {
        lhs.id == rhs.id
    }
}

// WorkoutPage model for organizing exercises
struct WorkoutPage: Identifiable {
    let id = UUID()
    var name: String
    var exercises: [UIExercise]
    
    init(name: String, exercises: [UIExercise]) {
        self.name = name
        self.exercises = exercises
    }
}