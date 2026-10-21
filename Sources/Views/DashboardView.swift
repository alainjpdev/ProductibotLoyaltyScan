import SwiftUI

struct DashboardView: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    
    @State private var isScannerPresented = false
    @State private var isLoggingOut = false
    @State private var showLogoutConfirm = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Fondo con degradado sofisticado en tonos oscuros
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.14),
                    Color(red: 0.04, green: 0.05, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Círculos sutiles de ambiente/luz de fondo
            GeometryReader { proxy in
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: proxy.size.width * 0.9)
                    .blur(radius: 60)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.45)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Barra Superior (Nombre de Tienda y Salir)
                headerView
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                Spacer()
                
                // MARK: - Botón Central Hero de Escaneo QR
                VStack(spacing: 28) {
                    scanHeroButton
                    
                    // Indicador de estado del sistema
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: .green, radius: 4)
                        
                        Text("Listo para escanear tarjetas y cupones")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                
                Spacer()
                
                // MARK: - Tarjeta de Último Escaneo (si existe)
                if let lastScan = supabase.lastScanResult {
                    lastScanCard(result: lastScan)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Spacer()
                        .frame(height: 50)
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
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(supabase.storeName ?? "Productibot Scan")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let staff = supabase.staffName {
                    Text(staff)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("Terminal de Escaneo")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Botón Salir
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
                            .font(.system(size: 13, weight: .semibold))
                        Text("Salir")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
            }
            .disabled(isLoggingOut)
        }
    }
    
    // MARK: - Botón Central Hero
    private var scanHeroButton: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            isScannerPresented = true
        }) {
            ZStack {
                // Anillo de pulso exterior
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 250, height: 250)
                    .scaleEffect(pulseAnimation ? 1.08 : 0.96)
                    .opacity(pulseAnimation ? 0.3 : 0.8)
                
                // Botón principal
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.38, blue: 0.95),
                                Color(red: 0.08, green: 0.22, blue: 0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 210, height: 210)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.blue.opacity(0.45), radius: 24, x: 0, y: 12)
                
                // Contenido del Botón
                VStack(spacing: 12) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    VStack(spacing: 2) {
                        Text("ESCANEAR QR")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1.2)
                        
                        Text("Toca para abrir cámara")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Tarjeta de Último Escaneo
    private func lastScanCard(result: ScanProcessResult) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(cardIconBg(result.type))
                    .frame(width: 44, height: 44)
                
                Image(systemName: cardIcon(result.type))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(cardIconColor(result.type))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(result.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Reciente")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if let name = result.clientName {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.cyan)
                }
                
                Text(result.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Funciones Auxiliares
    private func logout() {
        isLoggingOut = true
        Task {
            do {
                try await SupabaseManager.shared.signOut()
            } catch {
                print("Error signing out: \(error)")
                await MainActor.run {
                    isLoggingOut = false
                }
            }
        }
    }
    
    private func cardIcon(_ type: ScanResultType) -> String {
        switch type {
        case .visit: return "checkmark"
        case .reward: return "gift.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private func cardIconColor(_ type: ScanResultType) -> Color {
        switch type {
        case .visit: return .green
        case .reward: return .yellow
        case .error: return .red
        }
    }
    
    private func cardIconBg(_ type: ScanResultType) -> Color {
        switch type {
        case .visit: return Color.green.opacity(0.18)
        case .reward: return Color.yellow.opacity(0.18)
        case .error: return Color.red.opacity(0.18)
        }
    }
}

// MARK: - Estilo de Presión Suave para el Botón Hero
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
