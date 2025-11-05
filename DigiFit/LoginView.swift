import SwiftUI
import ComponentsKit

struct LoginView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToMain = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.85, green: 0.25, blue: 0.40), // Lighter red
                        Color(red: 0.75, green: 0.15, blue: 0.28)  // Darker red
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // DIGIFIT branding
                    VStack(spacing: 16) {
                        // Weights logo
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                            .symbolRenderingMode(.hierarchical)

                        Text("DIGIFIT")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Track your weightlifting progress")
                            .font(.system(.title3, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 60)

                    // Login form (collapsed by default)
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(.white)

                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .rounded))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(.white)

                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .rounded))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        // Error message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    Spacer()

                    // Action buttons
                    VStack(spacing: 20) {
                        // Log in button
                        SUButton(model: ButtonVM {
                            $0.title = isLoading ? "Logging in..." : "Log in"
                            $0.color = .primary
                            $0.isFullWidth = true
                            $0.size = .large
                            $0.style = .filled
                        }, action: {
                            Task {
                                await login()
                            }
                        })
                        .frame(height: 60)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)

                        // Sign up button - transparent
                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Don't have an account? Sign up")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
                    .navigationBarBackButtonHidden(true)
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func login() async {
        isLoading = true
        errorMessage = nil

        do {
            // Authenticate with Supabase
            try await supabaseManager.signIn(email: email, password: password)

            // Fetch or create profile from backend
            do {
                let _ = try await APIService.shared.getProfile()
            } catch {
                // If profile doesn't exist, create it
                if let userName = supabaseManager.currentUser?.userMetadata["name"]?.stringValue {
                    let _ = try await APIService.shared.createProfile(name: userName)
                }
            }

            // Navigate to main app
            await MainActor.run {
                navigateToMain = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Invalid email or password. Please try again."
                isLoading = false
            }
        }
    }
}

#Preview {
    LoginView()
}