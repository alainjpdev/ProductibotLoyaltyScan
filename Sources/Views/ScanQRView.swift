import SwiftUI
import CodeScanner

struct ScanQRView: View {
    @State private var isProcessing = false
    @State private var resultMessage: String?
    @State private var isSuccess = false
    
    var body: some View {
        VStack {
            if let msg = resultMessage {
                VStack(spacing: 20) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isSuccess ? .green : .red)
                    
                    Text(msg)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Escanear de nuevo") {
                        resultMessage = nil
                        isSuccess = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ZStack {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "test-qr-code") { response in
                        switch response {
                        case .success(let result):
                            processQR(result.string)
                        case .failure(let error):
                            resultMessage = "Error al escanear: \(error.localizedDescription)"
                            isSuccess = false
                        }
                    }
                    
                    VStack {
                        Spacer()
                        if isProcessing {
                            ProgressView("Procesando...")
                                .padding()
                                .background(Color(UIColor.systemBackground).opacity(0.8))
                                .cornerRadius(10)
                                .padding(.bottom, 50)
                        }
                    }
                }
            }
        }
        .navigationTitle("Escanear Cliente")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func processQR(_ token: String) {
        guard !isProcessing else { return }
        isProcessing = true
        
        Task {
            // Aquí iría la lógica para llamar al RPC de Supabase correspondiente
            // try await SupabaseManager.shared.client.rpc(...)
            
            // Simulación de proceso
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                resultMessage = "Código escaneado exitosamente:\n\(token)"
                isSuccess = true
                isProcessing = false
            }
        }
    }
}
