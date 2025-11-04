import SwiftUI
import ComponentsKit

struct LoginView: View {
    var body: some View {
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
            
            VStack {
                Spacer()
                
                // DIGIFIT text in the middle
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
                
                Spacer()
                
                VStack(spacing: 20) {
                    // Sign up button - same style as "Add Split" button
                    SUButton(model: ButtonVM {
                        $0.title = "Sign up"
                        $0.color = .primary
                        $0.isFullWidth = true
                        $0.size = .large
                        $0.style = .filled
                    }, action: {
                        // TODO: Add sign up action
                    })
                    .frame(height: 60)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    
                    // Log in button - transparent
                    Button(action: {
                        // TODO: Add log in action
                    }) {
                        Text("Log in")
                            .font(.system(.title3, design: .rounded).bold())
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
    }
}

#Preview {
    LoginView()
}

