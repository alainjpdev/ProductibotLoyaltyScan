import SwiftUI

struct DashboardView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    
    @State private var isScannerPresented = false
    @State private var isLoggingOut = false
    @State private var showLogoutConfirm = false
    @State private var isHoveringScan = false
    
    var body: some View {
        ZStack {
            // Fondo Uber Pure Black
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Barra Superior Uber Merchant Style
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 16)
                
                Divider()
                    .background(Color(white: 0.16))
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // MARK: - Barra de Estado (En Línea)
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 0.02, green: 0.76, blue: 0.40)) // Uber Green #06C167
                                .frame(width: 8, height: 8)
                            
                            Text("TERMINAL EN LÍNEA")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(1.0)
                                .foregroundColor(Color(red: 0.02, green: 0.76, blue: 0.40))
                            
                            Spacer()
                            
                            Text("Cámara lista")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(white: 0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(white: 0.16), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // MARK: - Tarjeta Central Hero de Escaneo (Uber Style)
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            isScannerPresented = true
                        }) {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 90, height: 90)
                                        .shadow(color: Color.white.opacity(0.15), radius: 16)
                                    
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 46, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                
                                VStack(spacing: 6) {
                                    Text("Escanear Código")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                        .tracking(-0.4)
                                    
                                    Text("Toca aquí para abrir la cámara y registrar visitas o cupones de Apple y Google Wallet")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color(white: 0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                }
                                
                                // Botón interior Uber
                                HStack(spacing: 8) {
                                    Text("ABRIR ESCÁNER")
                                        .font(.system(size: 13, weight: .bold))
                                        .tracking(0.6)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .clipShape(Capsule())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color(white: 0.09))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(white: 0.20), lineWidth: 1)
                            )
                        }
                        .buttonStyle(UberPressStyle())
                        .padding(.horizontal, 20)
                        
                        // MARK: - Actividad Reciente (Uber Card Style)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ÚLTIMO MOVIMIENTO")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Color(white: 0.5))
                                .padding(.horizontal, 20)
                            
                            if let lastScan = supabase.lastScanResult {
                                recentScanUberCard(result: lastScan)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            } else {
                                emptyActivityCard
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isScannerPresented) {
            ScanQRView()
        }
        .confirmationDialog(
            "¿Deseas cerrar sesión?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Cerrar Sesión", role: .destructive) {
                logout()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header Uber Style
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(supabase.storeName ?? "Top Scan")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let staff = supabase.staffName {
                        Text(staff)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(white: 0.7))
                    } else {
                        Text("Terminal de Caja")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(white: 0.55))
                    }
                    
                    if let role = supabase.staffRole {
                        Text("• \(role.capitalized)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(white: 0.45))
                    }
                }
            }
            
            Spacer()
            
            // Botón Salir Uber Style
            Button(action: {
                showLogoutConfirm = true
            }) {
                if isLoggingOut {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 36, height: 36)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 12, weight: .bold))
                        Text("Salir")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.14))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(white: 0.25), lineWidth: 1)
                    )
                }
            }
            .disabled(isLoggingOut)
        }
    }
    
    // MARK: - Tarjeta de Último Escaneo Uber
    private func recentScanUberCard(result: ScanProcessResult) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(badgeBg(result.type))
                    .frame(width: 44, height: 44)
                
                Image(systemName: badgeIcon(result.type))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(badgeColor(result.type))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Hace un momento")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.45))
                }
                
                if let name = result.clientName {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(white: 0.85))
                }
                
                Text(result.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.6))
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(Color(white: 0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(white: 0.18), lineWidth: 1)
        )
    }
    
    // MARK: - Empty State
    private var emptyActivityCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.12))
                    .frame(width: 42, height: 42)
                
                Image(systemName: "clock")
                    .font(.system(size: 18))
                    .foregroundColor(Color(white: 0.4))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Sin escaneos recientes")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(white: 0.7))
                
                Text("Los registros del turno aparecerán aquí")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.4))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(white: 0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(white: 0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Helpers
    private func logout() {
        isLoggingOut = true
        Task {
            do {
                try await SupabaseManager.shared.signOut()
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                }
            }
        }
    }
    
    private func badgeIcon(_ type: ScanResultType) -> String {
        switch type {
        case .visit: return "checkmark"
        case .reward: return "gift.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private func badgeColor(_ type: ScanResultType) -> Color {
        switch type {
        case .visit: return Color(red: 0.02, green: 0.76, blue: 0.40) // Uber Green
        case .reward: return Color(red: 1.0, green: 0.75, blue: 0.26) // Gold
        case .error: return Color(red: 0.95, green: 0.25, blue: 0.25) // Red
        }
    }
    
    private func badgeBg(_ type: ScanResultType) -> Color {
        switch type {
        case .visit: return Color(red: 0.02, green: 0.76, blue: 0.40).opacity(0.18)
        case .reward: return Color(red: 1.0, green: 0.75, blue: 0.26).opacity(0.18)
        case .error: return Color(red: 0.95, green: 0.25, blue: 0.25).opacity(0.18)
        }
    }
}

// MARK: - Efecto Uber Press Feedback
struct UberPressStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
