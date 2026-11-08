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
            
            // 2. Máscara y Retícula Uber Minimalist
            viewfinderOverlay
            
            // 3. Barra Superior (Cerrar y Linterna Uber Style)
            VStack {
                topControlBar
                Spacer()
            }
            
            // 4. Overlay de Procesamiento
            if isProcessing {
                processingOverlay
            }
            
            // 5. Tarjeta Modal de Resultado Uber Style
            if let result = scanResult {
                resultModalOverlay(result: result)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startLaserAnimation()
        }
    }
    
    // MARK: - Barra Superior Uber Style
    private var topControlBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("Cerrar")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(white: 0.3), lineWidth: 1)
                )
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTorchOn.toggle()
                }
            }) {
                Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isTorchOn ? Color(red: 1.0, green: 0.8, blue: 0.2) : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }
    
    // MARK: - Retícula del Viewfinder Uber Minimalist
    private var viewfinderOverlay: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                // Marco central
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: 250, height: 250)
                
                // Esquinas Uber (blanco sólido nítido)
                ViewfinderCorners()
                    .stroke(Color.white, lineWidth: 3.5)
                    .frame(width: 250, height: 250)
                
                // Línea láser Uber Green
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(red: 0.02, green: 0.76, blue: 0.40).opacity(0.9), // Uber Green
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 230, height: 2.5)
                    .offset(y: laserOffset)
            }
            
            // Indicador de instrucción Uber Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(red: 0.02, green: 0.76, blue: 0.40))
                    .frame(width: 6, height: 6)
                Text("Enfoca el código QR de la tarjeta o cupón")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(white: 0.25), lineWidth: 1)
            )
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Overlay de Procesamiento
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)
                
                Text("Verificando en el sistema...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(26)
            .background(Color(white: 0.12))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(white: 0.25), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Tarjeta Modal de Resultado Uber Style
    private func resultModalOverlay(result: ScanProcessResult) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Ícono de estado
                ZStack {
                    Circle()
                        .fill(resultColor(result.type).opacity(0.18))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: resultIcon(result.type))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(resultColor(result.type))
                }
                .padding(.top, 6)
                
                // Títulos
                VStack(spacing: 6) {
                    Text(result.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let client = result.clientName {
                        Text(client)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(white: 0.85))
                    }
                    
                    Text(result.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(white: 0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                
                if let detail = result.detail {
                    Text(detail)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(white: 0.45))
                        .multilineTextAlignment(.center)
                }
                
                Divider()
                    .background(Color(white: 0.18))
                    .padding(.vertical, 4)
                
                // Botones Uber Style
                VStack(spacing: 10) {
                    // Botón Principal Blanco Uber
                    Button(action: resetScannerForNext) {
                        HStack(spacing: 8) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 15, weight: .bold))
                            Text("Escanear Otro")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    
                    // Botón Secundario Cerrar
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Terminar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(white: 0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(Color(white: 0.10))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(white: 0.22), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.8), radius: 30)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Manejo de Escaneo
    private func handleScannedCode(_ code: String) {
        guard !isProcessing && scanResult == nil else { return }
        isProcessing = true
        
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
            return Color(red: 0.02, green: 0.76, blue: 0.40) // Uber Green
        case .reward:
            return Color(red: 1.0, green: 0.75, blue: 0.26) // Gold
        case .error:
            return Color(red: 0.95, green: 0.25, blue: 0.25) // Red
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
        let length: CGFloat = 30
        let radius: CGFloat = 14
        
        // Top-Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        
        // Top-Right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + length))
        
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
