import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    // TODO: Replace with your actual Supabase credentials
    // Get these from: https://app.supabase.com/project/_/settings/api
    // Load from Config.plist
    private let supabaseURL: String
    private let supabaseKey: String

    private(set) var client: SupabaseClient!

    @Published var currentUser: User?
    @Published var session: Session?
    @Published var isAuthenticated: Bool = false

    private init() {
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )

        // Listen for auth state changes
        Task {
            for await state in await client.auth.authStateChanges {
                await MainActor.run {
                    self.session = state.session
                    self.currentUser = state.session?.user
                    self.isAuthenticated = state.session != nil
                }
            }
        }

        // Check for existing session on app launch
        Task {
            await checkSession()
        }
    }

    // MARK: - Authentication Methods

    /// Sign up a new user with email and password
    func signUp(email: String, password: String, name: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )

        guard response.session != nil else {
            throw NSError(
                domain: "SupabaseManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create session. Please check your email for verification."]
            )
        }

        await MainActor.run {
            self.session = response.session
            self.currentUser = response.session?.user
            self.isAuthenticated = true
        }
    }

    /// Sign in an existing user
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(email: email, password: password)

        await MainActor.run {
            self.session = response.session
            self.currentUser = response.user
            self.isAuthenticated = true
        }
    }

    /// Sign out the current user
    func signOut() async throws {
        try await client.auth.signOut()

        await MainActor.run {
            self.session = nil
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    /// Get JWT access token for backend authentication
    func getAccessToken() async throws -> String {
        guard let session = await client.auth.session else {
            throw NSError(
                domain: "SupabaseManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
        }
        return session.accessToken
    }

    /// Get current user's ID
    func getUserId() -> String? {
        return currentUser?.id.uuidString
    }

    // MARK: - Private Methods

    /// Check for existing session on app launch
    private func checkSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.session = session
                self.currentUser = session.user
                self.isAuthenticated = true
            }
        } catch {
            // No existing session - user needs to log in
            await MainActor.run {
                self.session = nil
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
}