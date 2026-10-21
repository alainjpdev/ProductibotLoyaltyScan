import Foundation
@preconcurrency import Supabase

enum ScanResultType: Sendable {
    case visit
    case reward
    case error
}

struct ScanProcessResult: Identifiable, Sendable {
    let id = UUID()
    let type: ScanResultType
    let title: String
    let subtitle: String
    let clientName: String?
    let detail: String?
    let isCycleUnlocked: Bool
    let timestamp: Date
    
    init(type: ScanResultType, title: String, subtitle: String, clientName: String? = nil, detail: String? = nil, isCycleUnlocked: Bool = false) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.clientName = clientName
        self.detail = detail
        self.isCycleUnlocked = isCycleUnlocked
        self.timestamp = Date()
    }
}

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    @Published var isAuthenticated = false
    @Published var storeId: String?
    @Published var storeLogoUrl: String?
    @Published var storeName: String?
    @Published var staffId: String?
    @Published var staffName: String?
    @Published var staffRole: String?
    @Published var lastScanResult: ScanProcessResult?
    
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
                        self.staffId = nil
                        self.staffName = nil
                        self.staffRole = nil
                        self.lastScanResult = nil
                    }
                }
                
                if hasSession {
                    await fetchStoreDetails()
                }
            }
        }
    }
    
    func fetchStoreDetails() async {
        do {
            let session = try await client.auth.session
            let userId = session.user.id
            
            struct StaffProfile: Decodable, Sendable {
                let store_id: String
                let full_name: String?
                let role: String?
            }
            
            let staffList: [StaffProfile] = (try? await client
                .from("staff_profiles")
                .select("store_id, full_name, role")
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value) ?? []
            
            let staff = staffList.first
            let targetStoreId = staff?.store_id ?? Configuration.storeId
            
            struct StoreProfile: Decodable, Sendable {
                let name: String?
                let logo_url: String?
            }
            
            let storeList: [StoreProfile] = (try? await client
                .from("stores")
                .select("name, logo_url")
                .eq("id", value: targetStoreId)
                .limit(1)
                .execute()
                .value) ?? []
            
            let store = storeList.first
            
            await MainActor.run {
                self.staffId = userId.uuidString
                self.staffName = staff?.full_name
                self.staffRole = staff?.role
                self.storeId = targetStoreId
                self.storeName = store?.name ?? "Productibot Loyalty"
                self.storeLogoUrl = store?.logo_url
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
            staffId = nil
            staffName = nil
            staffRole = nil
            lastScanResult = nil
        }
    }
    
    // MARK: - Procesamiento Inteligente de Códigos QR
    func processScannedCode(_ rawCode: String) async -> ScanProcessResult {
        guard let uuid = extractUUID(from: rawCode) else {
            return ScanProcessResult(
                type: .error,
                title: "Código No Válido",
                subtitle: "El formato del QR no corresponde a un ID reconocido."
            )
        }
        
        let activeStoreId = self.storeId ?? Configuration.storeId
        let currentStaffId = self.staffId
        
        // 1. Verificar si es un Cupón de Premio (coupons)
        do {
            struct CouponRecord: Decodable, Sendable {
                let id: String
                let profile_id: String
                let store_id: String?
                let reward_description: String
                let status: String
            }
            
            let coupons: [CouponRecord] = try await client
                .from("coupons")
                .select("id, profile_id, store_id, reward_description, status")
                .eq("id", value: uuid)
                .limit(1)
                .execute()
                .value
            
            if let coupon = coupons.first {
                if let cStore = coupon.store_id, cStore != activeStoreId {
                    return ScanProcessResult(
                        type: .error,
                        title: "Sucursal Incorrecta",
                        subtitle: "Este cupón pertenece a otra sucursal y no puede canjearse aquí."
                    )
                }
                
                if coupon.status.lowercased() == "redeemed" {
                    return ScanProcessResult(
                        type: .error,
                        title: "Cupón Ya Canjeado",
                        subtitle: "Este cupón de premio ya fue canjeado con anterioridad."
                    )
                }
                
                // Canjear cupón en base de datos
                let nowString = ISO8601DateFormatter().string(from: Date())
                struct UpdateCouponPayload: Encodable, Sendable {
                    let status: String
                    let redeemed_at: String
                    let redeemed_by: String?
                }
                
                try await client
                    .from("coupons")
                    .update(UpdateCouponPayload(status: "redeemed", redeemed_at: nowString, redeemed_by: currentStaffId))
                    .eq("id", value: coupon.id)
                    .execute()
                
                // Registrar movimiento en el libro mayor
                struct InsertTxPayload: Encodable, Sendable {
                    let store_id: String
                    let profile_id: String
                    let visits_change: Int
                    let description: String
                    let staff_id: String?
                }
                
                let cleanReward = coupon.reward_description.hasPrefix("Promo:")
                    ? coupon.reward_description.replacingOccurrences(of: "Promo: ", with: "")
                    : coupon.reward_description
                
                _ = try? await client
                    .from("loyalty_transactions")
                    .insert(InsertTxPayload(
                        store_id: activeStoreId,
                        profile_id: coupon.profile_id,
                        visits_change: 0,
                        description: "Canje Premio: \(cleanReward)",
                        staff_id: currentStaffId
                    ))
                    .execute()
                
                // Obtener nombre del cliente
                struct ProfileNameRecord: Decodable, Sendable {
                    let full_name: String?
                    let email: String?
                }
                let profiles: [ProfileNameRecord] = (try? await client
                    .from("profiles")
                    .select("full_name, email")
                    .eq("id", value: coupon.profile_id)
                    .limit(1)
                    .execute()
                    .value) ?? []
                
                let clientName = profiles.first?.full_name ?? profiles.first?.email ?? "Cliente"
                
                let result = ScanProcessResult(
                    type: .reward,
                    title: "¡Premio Canjeado!",
                    subtitle: cleanReward,
                    clientName: clientName,
                    detail: "Premio canjeado con éxito y registrado en el historial.",
                    isCycleUnlocked: false
                )
                self.lastScanResult = result
                return result
            }
        } catch {
            print("Error al verificar cupón: \(error)")
        }
        
        // 2. Verificar si es un Perfil de Cliente (profiles)
        do {
            struct ProfileRecord: Decodable, Sendable {
                let id: String
                let full_name: String?
                let email: String?
            }
            
            let profiles: [ProfileRecord] = try await client
                .from("profiles")
                .select("id, full_name, email")
                .eq("id", value: uuid)
                .limit(1)
                .execute()
                .value
            
            if let clientProf = profiles.first {
                let clientName = clientProf.full_name ?? clientProf.email ?? "Cliente"
                
                // Incrementar visitas / sellos vía RPC
                struct IncrementVisitsParams: Encodable, Sendable {
                    let p_profile_id: String
                    let p_store_id: String
                    let p_amount: Int
                }
                
                struct IncrementVisitsResponse: Decodable, Sendable {
                    let success: Bool?
                    let loyalty_type: String?
                    let visits: Int?
                    let stamps_current: Int?
                    let stamp_target: Int?
                    let stamp_cycles_completed: Int?
                    let cycle_unlocked: Bool?
                    let reward_title: String?
                }
                
                let rpcRes: IncrementVisitsResponse = try await client
                    .rpc("increment_visits", params: IncrementVisitsParams(
                        p_profile_id: clientProf.id,
                        p_store_id: activeStoreId,
                        p_amount: 1
                    ))
                    .execute()
                    .value
                
                // Registrar transacción en loyalty_transactions
                struct InsertTxPayload: Encodable, Sendable {
                    let store_id: String
                    let profile_id: String
                    let visits_change: Int
                    let description: String
                    let staff_id: String?
                }
                
                _ = try? await client
                    .from("loyalty_transactions")
                    .insert(InsertTxPayload(
                        store_id: activeStoreId,
                        profile_id: clientProf.id,
                        visits_change: 1,
                        description: "Visita Registrada",
                        staff_id: currentStaffId
                    ))
                    .execute()
                
                let isCycleUnlocked = rpcRes.cycle_unlocked ?? false
                let currentStamps = rpcRes.stamps_current ?? rpcRes.visits ?? 1
                let targetStamps = rpcRes.stamp_target ?? 10
                let rewardTitle = rpcRes.reward_title ?? "1 Recompensa Especial"
                
                let result: ScanProcessResult
                if isCycleUnlocked {
                    result = ScanProcessResult(
                        type: .reward,
                        title: "🎉 ¡Tarjeta Completada!",
                        subtitle: "¡Desbloqueó: \(rewardTitle)!",
                        clientName: clientName,
                        detail: "Se generó su cupón de premio automáticamente.",
                        isCycleUnlocked: true
                    )
                } else {
                    result = ScanProcessResult(
                        type: .visit,
                        title: "⭐ ¡Visita Registrada!",
                        subtitle: "\(currentStamps) de \(targetStamps) sellos acumulados",
                        clientName: clientName,
                        detail: "+1 Sello añadido a su tarjeta de lealtad.",
                        isCycleUnlocked: false
                    )
                }
                
                self.lastScanResult = result
                return result
            }
        } catch {
            print("Error al verificar cliente: \(error)")
        }
        
        // 3. Si no coincide con cupón ni con cliente
        let notFound = ScanProcessResult(
            type: .error,
            title: "Código No Reconocido",
            subtitle: "El código no pertenece a ningún cliente o cupón activo en el sistema."
        )
        return notFound
    }
    
    private func extractUUID(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsString = trimmed as NSString
            let results = regex.matches(in: trimmed, range: NSRange(location: 0, length: nsString.length))
            if let match = results.first {
                return nsString.substring(with: match.range).lowercased()
            }
        }
        return nil
    }
}
