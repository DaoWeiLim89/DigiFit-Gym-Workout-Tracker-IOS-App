import Foundation

class APIService {
    static let shared = APIService()

    // Update with your backend URL
    private let baseURL = "http://18.217.199.136:8080" // Change for production

    private init() {}

    // MARK: - Generic Request Method
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add JWT token from Supabase
        if let token = try? await SupabaseManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Profile APIs
    func createProfile(name: String) async throws -> Profile {
        let body = try JSONEncoder().encode(["name": name])
        return try await makeRequest(endpoint: "/profiles", method: "POST", body: body)
    }

    func getProfile() async throws -> Profile {
        return try await makeRequest(endpoint: "/profiles/me")
    }

    // MARK: - Workout Split APIs
    func getWorkoutSplits() async throws -> [WorkoutSplit] {
        return try await makeRequest(endpoint: "/splits")
    }

    func createWorkoutSplit(name: String) async throws -> WorkoutSplit {
        let body = try JSONEncoder().encode(["name": name])
        return try await makeRequest(endpoint: "/splits", method: "POST", body: body)
    }

    func getExercises(splitId: Int) async throws -> [Exercise] {
        return try await makeRequest(endpoint: "/splits/\(splitId)/exercises")
    }

    // MARK: - Workout Entry APIs
    func logWorkout(exerciseId: Int, weight: Double, reps: Int, date: Date) async throws -> WorkoutEntry {
        let body = try JSONEncoder().encode([
            "exerciseId": exerciseId,
            "weight": weight,
            "reps": reps,
            "date": ISO8601DateFormatter().string(from: date)
        ])
        return try await makeRequest(endpoint: "/entries", method: "POST", body: body)
    }

    func getWorkoutHistory(exerciseId: Int) async throws -> [WorkoutEntry] {
        return try await makeRequest(endpoint: "/exercises/\(exerciseId)/entries")
    }
}