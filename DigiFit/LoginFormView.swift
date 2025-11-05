import SwiftUI
import ComponentsKit

struct LoginFormView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background matching signup page
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
                            Text("Welcome Back")
                                .font(.system(.largeTitle, design: .rounded).bold())
                                .foregroundColor(.white)
                            
                            Text("Log in to continue tracking")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Form fields
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
                        }
                        .padding(.horizontal, 20)
                        
                        // Error message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 20)
                        }
                        
                        // Log in button
                        SUButton(model: ButtonVM {
                            $0.title = isLoading ? "Logging in..." : "Log In"
                            $0.color = .primary
                            $0.isFullWidth = true
                            $0.size = .large
                            $0.style = .filled
                        }, action: {
                            Task {
                                await logIn()
                            }
                        })
                        .frame(height: 60)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        
                        // Don't have an account link
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Don't have an account? Sign up")
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
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func logIn() async {
        errorMessage = nil
        
        // Validate form
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }
        
        isLoading = true
        
        do {
            try await supabaseManager.signIn(email: email, password: password)
            // Success - dismiss the view or navigate to main app
            await MainActor.run {
                dismiss()
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
    LoginFormView()
}

