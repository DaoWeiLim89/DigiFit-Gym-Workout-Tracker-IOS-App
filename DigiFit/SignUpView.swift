import SwiftUI
import ComponentsKit

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccess: Bool = false
    @State private var navigateToMain = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background matching login page
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.85, green: 0.25, blue: 0.40), // Lighter red
                        Color(red: 0.75, green: 0.15, blue: 0.28)  // Darker red
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Create Account")
                                .font(.system(.largeTitle, design: .rounded).bold())
                                .foregroundColor(.white)

                            Text("Sign up to track your progress")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)

                        // Form fields
                        VStack(spacing: 16) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(.white)

                                TextField("Enter your name", text: $name)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .rounded))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                                    .autocapitalization(.words)
                                    .autocorrectionDisabled()
                            }

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

                            // Confirm Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundColor(.white)

                                SecureField("Confirm your password", text: $confirmPassword)
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
                        }
                        .padding(.horizontal, 20)

                        // Error message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 20)
                        }

                        // Sign up button
                        SUButton(model: ButtonVM {
                            $0.title = isLoading ? "Creating Account..." : "Sign Up"
                            $0.color = .primary
                            $0.isFullWidth = true
                            $0.size = .large
                            $0.style = .filled
                        }, action: {
                            Task {
                                await signUp()
                            }
                        })
                        .frame(height: 60)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)

                        // Already have an account link
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Already have an account? Log in")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
                    .navigationBarBackButtonHidden(true)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Account created successfully! You can now log in.")
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        isValidEmail(email) &&
        password.count >= 6
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func signUp() async {
        errorMessage = nil

        // Validate form
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isLoading = true

        do {
            // Sign up with Supabase
            try await supabaseManager.signUp(email: email, password: password, name: name)

            // Create profile in backend
            do {
                let _ = try await APIService.shared.createProfile(name: name)
            } catch {
                // If profile creation fails, it's okay - we'll create it on first login
                print("Profile creation failed: \(error)")
            }

            // Navigate to main app or show success
            await MainActor.run {
                if supabaseManager.isAuthenticated {
                    navigateToMain = true
                } else {
                    showSuccess = true
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    SignUpView()
}