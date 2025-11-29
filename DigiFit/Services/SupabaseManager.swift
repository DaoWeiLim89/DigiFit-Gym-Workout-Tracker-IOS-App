import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    // Supabase credentials
    // Load from Config.plist or use fallback values
    private let supabaseURL: String
    private let supabaseKey: String

    private(set) var client: SupabaseClient!

    @Published var currentUser: User?
    @Published var session: Session?
    @Published var isAuthenticated: Bool = false

    private init() {
        // Load configuration from Config.plist
        guard let configURL = Bundle.main.url(forResource: "Config", withExtension: "plist"),
           let configData = try? Data(contentsOf: configURL),
           let config = try? PropertyListDecoder().decode([String: String].self, from: configData),
           let url = config["SUPABASE_URL"],
              let key = config["SUPABASE_KEY"] else {
            fatalError("""
                Config.plist not found or missing required keys.
                
                Create a Config.plist in the DigiFit folder with:
                - SUPABASE_URL: Your Supabase project URL
                - SUPABASE_KEY: Your Supabase API key (prefer anon key for client apps)
                - BACKEND_URL: Your backend API URL
                
                See Config.plist.example for the format.
                """)
        }
        
        self.supabaseURL = url
        self.supabaseKey = key
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL: \(supabaseURL)")
        }

        // Configure AuthClient to emit local session as initial session
        // This fixes the deprecation warning
        let authConfig = AuthClient.Configuration(
            emitLocalSessionAsInitialSession: true
        )
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey,
            auth: AuthClient(configuration: authConfig)
        )

        // Listen for auth state changes
        // With emitLocalSessionAsInitialSession: true, this will automatically
        // emit the stored session on app launch, so no need for manual checkSession()
        Task {
            for await state in client.auth.authStateChanges {
                await MainActor.run {
                    updateSessionState(state.session)
                }
            }
        }
        
        // Validate and refresh session on app launch to catch stale sessions
        // This runs after the initial session is emitted, so we can verify it's still valid
        Task {
            await validateAndRefreshSession()
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

        // Update state immediately for responsive UI
        // The authStateChanges stream will also fire to keep state in sync
        await MainActor.run {
            updateSessionState(response.session)
        }
    }

    /// Sign in an existing user
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(email: email, password: password)

        // Update state immediately for responsive UI
        // The authStateChanges stream will also fire to keep state in sync
        await MainActor.run {
            updateSessionState(response)
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
        let session = try await client.auth.session
        return session.accessToken
    }

    /// Get current user's ID
    func getUserId() -> String? {
        return currentUser?.id.uuidString
    }

    // MARK: - Private Methods

    /// Update session state from auth state changes or manual updates
    /// Handles expired sessions and keeps state synchronized
    private func updateSessionState(_ session: Session?) {
        // Check if session is expired
        if let session = session, session.isExpired {
            // Session is expired, clear it
            self.session = nil
            self.currentUser = nil
            self.isAuthenticated = false
        } else {
            // Valid session (or no session)
            self.session = session
            self.currentUser = session?.user
            self.isAuthenticated = session != nil
        }
    }

    private func validateAndRefreshSession() async {
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        do {
            // Try to get the current session
            // This will automatically attempt to refresh if expired
            // If refresh fails (e.g., refresh token expired, user deleted, etc.), it throws
            let session = try await client.auth.session
            
            // If we get here, session is valid (either was valid or was successfully refreshed)
            // The authStateChanges stream should have already updated our state,
            // but we verify consistency
            await MainActor.run {
                if self.session?.accessToken != session.accessToken {
                    self.session = session
                    self.currentUser = session.user
                    self.isAuthenticated = true
                }
            }
        } catch {
            // Session is invalid, refresh failed, or no session exists
            // Clear the session state to ensure UI shows logged out state
            await MainActor.run {
                if self.isAuthenticated {
                    self.session = nil
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
}
