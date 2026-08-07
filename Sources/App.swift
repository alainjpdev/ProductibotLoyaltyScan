import SwiftUI

@main
struct ProductibotLoyaltyScanApp: App {
    @StateObject private var supabase = SupabaseManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if supabase.isAuthenticated {
                    DashboardView()
                } else {
                    LoginView()
                }
            }
            .animation(.default, value: supabase.isAuthenticated)
            .preferredColorScheme(.dark)
        }
    }
}
