import Foundation
@preconcurrency import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    @Published var isAuthenticated = false
    @Published var storeId: String?
    @Published var storeLogoUrl: String?
    @Published var storeName: String?
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: Configuration.supabaseURL,
            supabaseKey: Configuration.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        Task {
            for await state in client.auth.authStateChanges {
                let hasSession = state.session != nil
                await MainActor.run {
                    self.isAuthenticated = hasSession
                    if !hasSession {
                        self.storeId = nil
                        self.storeLogoUrl = nil
                        self.storeName = nil
                    }
                }
                
                if hasSession {
                    await fetchStoreDetails()
                }
            }
        }
    }
    
    private func fetchStoreDetails() async {
        do {
            let session = try await client.auth.session
            let userId = session.user.id
            
            struct StaffProfile: Decodable {
                let store_id: String
            }
            let staff: StaffProfile = try await client
                .from("staff_profiles")
                .select("store_id")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            struct StoreProfile: Decodable {
                let name: String?
            }
            let store: StoreProfile = try await client
                .from("stores")
                .select("name")
                .eq("id", value: staff.store_id)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.storeId = staff.store_id
                self.storeName = store.name
            }
        } catch {
            print("Error fetching store details: \(error)")
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        await MainActor.run {
            isAuthenticated = false
            storeId = nil
            storeLogoUrl = nil
            storeName = nil
        }
    }
}
