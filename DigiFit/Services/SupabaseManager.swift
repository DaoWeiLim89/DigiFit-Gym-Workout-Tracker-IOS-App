import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    // Get these from your Supabase project dashboard
    private let supabaseURL = "YOUR_SUPABASE_PROJECT_URL" // e.g., https://xxxxx.supabase.co
    private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"

    private(set) var client: SupabaseClient!

    @Published var currentUser: User?
    @Published var session: Session?

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )

        // Listen for auth state changes
        Task {
            for await state in await client.auth.authStateChanges {
                await MainActor.run {
                    self.session = state.session
                    self.currentUser = state.session?.user
                }
            }
        }
    }

    func signUp(email: String, password: String, name: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )

        guard response.session != nil else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create session"])
        }
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // Get JWT token for backend authentication
    func getAccessToken() async throws -> String {
        guard let session = await client.auth.session else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "No active session"])
        }
        return session.accessToken
    }
}