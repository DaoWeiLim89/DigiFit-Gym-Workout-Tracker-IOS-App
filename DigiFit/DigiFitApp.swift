//
//  DigiFitApp.swift
//  DigiFit
//
//  Created by Dao Wei Lim on 31/10/25.
//

import SwiftUI

@main
struct DigiFitApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .animation(.easeInOut, value: supabaseManager.isAuthenticated)
        }
    }
}
