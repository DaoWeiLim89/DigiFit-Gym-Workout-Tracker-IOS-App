import SwiftUI

struct MainTabView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Workouts Tab
            LandingPageView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(0)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(Color(red: 0.86, green: 0.08, blue: 0.24)) // Match app theme
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var profile: Profile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = profile {
                    Form {
                        Section("Personal Information") {
                            HStack {
                                Text("Name")
                                Spacer()
                                Text(profile.name)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let email = profile.email {
                                HStack {
                                    Text("Email")
                                    Spacer()
                                    Text(email)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if let height = profile.height, let weight = profile.weight {
                            Section("Body Metrics") {
                                HStack {
                                    Text("Height")
                                    Spacer()
                                    Text("\(String(format: "%.1f", height)) \(profile.heightUnit ?? "cm")")
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Weight")
                                    Spacer()
                                    Text("\(String(format: "%.1f", weight)) \(profile.weightUnit ?? "kg")")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Failed to load profile")
                            .font(.headline)
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Button("Retry") {
                            loadProfile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .task {
                loadProfile()
            }
        }
    }
    
    private func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedProfile = try await APIService.shared.getProfile()
                await MainActor.run {
                    self.profile = fetchedProfile
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var showLogoutAlert = false
    @State private var isLoggingOut = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let user = supabaseManager.currentUser {
                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(user.id.uuidString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let email = user.email {
                            HStack {
                                Text("Email")
                                Spacer()
                                Text(email)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            if isLoggingOut {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Sign Out")
                        }
                    }
                    .disabled(isLoggingOut)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private func signOut() {
        isLoggingOut = true
        
        Task {
            do {
                try await supabaseManager.signOut()
                await MainActor.run {
                    isLoggingOut = false
                }
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                    // Handle error if needed
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}


