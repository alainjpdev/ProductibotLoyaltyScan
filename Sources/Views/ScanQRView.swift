import SwiftUI
import CodeScanner
import AudioToolbox

struct ScanQRView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var supabase = SupabaseManager.shared
    
    @State private var isProcessing = false
    @State private var isTorchOn = false
    @State private var scanResult: ScanProcessResult?
    @State private var laserOffset: CGFloat = -110
    
    var body: some View {
        ZStack {
            // Fondo oscuro para cámara
            Color.black.ignoresSafeArea()
            
            // 1. Escáner de Código QR
            CodeScannerView(
                codeTypes: [.qr],
                scanMode: .once,
                showViewfinder: false,
                isTorchOn: isTorchOn
            ) { response in
                switch response {
                case .success(let result):
                    handleScannedCode(result.string)
                case .failure(let error):
                    handleError(error.localizedDescription)
                }
            }
            .ignoresSafeArea()
            
            // 2. Máscara y Retícula de Enfoque con Láser
            viewfinderOverlay
            
            // 3. Barra Superior (Cancelar y Linterna)
            VStack {
                topControlBar
                Spacer()
            }
            
            // 4. Overlay de Carga durante la verificación con Supabase
            if isProcessing {
                processingOverlay
            }
            
            // 5. Tarjeta de Resultado (Éxito o Error)
            if let result = scanResult {
                resultModalOverlay(result: result)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startLaserAnimation()
        }
    }
    
    // MARK: - Barra Superior
    private var topControlBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                    Text("Cerrar")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTorchOn.toggle()
                }
            }) {
                Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isTorchOn ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
    
    // MARK: - Retícula del Viewfinder y Láser
    private var viewfinderOverlay: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                // Marco transparente central
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: 260, height: 260)
                
                // Esquinas destacadas
                ViewfinderCorners()
                    .stroke(Color(red: 0.2, green: 0.6, blue: 1.0), lineWidth: 4)
                    .frame(width: 260, height: 260)
                
                // Línea láser animada
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.cyan.opacity(0.8), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 240, height: 3)
                    .shadow(color: .cyan, radius: 8, x: 0, y: 0)
                    .offset(y: laserOffset)
            }
            
            // Indicador de instrucción
            Text("Apunta al código QR del cliente o cupón")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.4), radius: 8)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Overlay de Procesamiento
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.4)
                
                Text("Validando en el sistema...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
        }
    }
    
    // MARK: - Tarjeta Modal de Resultado
    private func resultModalOverlay(result: ScanProcessResult) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tap afuera no cierra si está procesando
                }
            
            VStack(spacing: 20) {
                // Ícono de estado
                ZStack {
                    Circle()
                        .fill(resultColor(result.type).opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: resultIcon(result.type))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(resultColor(result.type))
                }
                .padding(.top, 8)
                
                // Títulos
                VStack(spacing: 8) {
                    Text(result.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let client = result.clientName {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.cyan)
                            Text(client)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.95))
                        }
                    }
                    
                    Text(result.subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                
                if let detail = result.detail {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 4)
                
                // Botones de Acción
                VStack(spacing: 12) {
                    Button(action: resetScannerForNext) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Escanear Otro")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color(red: 0.1, green: 0.4, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Terminar")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.12, blue: 0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(resultColor(result.type).opacity(0.4), lineWidth: 1.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.6), radius: 30)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Manejo de Escaneo
    private func handleScannedCode(_ code: String) {
        guard !isProcessing && scanResult == nil else { return }
        isProcessing = true
        
        // Sonido de Beep y Haptic inmediato
        AudioServicesPlaySystemSound(1057)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        Task {
            let result = await supabase.processScannedCode(code)
            
            await MainActor.run {
                self.isProcessing = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.scanResult = result
                }
                
                // Haptic de Confirmación
                let notification = UINotificationFeedbackGenerator()
                if result.type == .error {
                    notification.notificationOccurred(.error)
                } else {
                    notification.notificationOccurred(.success)
                }
            }
        }
    }
    
    private func handleError(_ message: String) {
        guard !isProcessing && scanResult == nil else { return }
        let errResult = ScanProcessResult(
            type: .error,
            title: "Error de Escaneo",
            subtitle: message
        )
        withAnimation {
            self.scanResult = errResult
        }
    }
    
    private func resetScannerForNext() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.scanResult = nil
            self.isProcessing = false
        }
        startLaserAnimation()
    }
    
    private func startLaserAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            laserOffset = 110
        }
    }
    
    private func resultColor(_ type: ScanResultType) -> Color {
        switch type {
        case .visit:
            return Color.green
        case .reward:
            return Color.yellow
        case .error:
            return Color.red
        }
    }
    
    private func resultIcon(_ type: ScanResultType) -> String {
        switch type {
        case .visit:
            return "checkmark.circle.fill"
        case .reward:
            return "gift.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }
}

// MARK: - Trazo de Esquinas para el Viewfinder
struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length: CGFloat = 32
        let radius: CGFloat = 16
        
        // Top-Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        
        // Top-Right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        
        // Bottom-Right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        
        // Bottom-Left
        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        
        return path
    }
}
