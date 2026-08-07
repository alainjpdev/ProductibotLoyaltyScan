import SwiftUI
import CoreImage.CIFilterBuiltins
@preconcurrency import Supabase

struct GenerateQRView: View {
    @State private var qrImage: UIImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("QR para Cliente")
                .font(.title)
                .bold()
            
            Text("Muestra este código al cliente para que lo escanee y acumule su visita.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView("Generando código...")
                    .frame(height: 250)
            } else if let img = qrImage {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
            } else if let err = errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .frame(height: 250)
            }
            
            Spacer()
            
            Button("Refrescar Código") {
                generateTokenAndQR()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onAppear {
            if qrImage == nil {
                generateTokenAndQR()
            }
        }
        .navigationTitle("Generar QR")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func generateTokenAndQR() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id
                
                let expiresAt = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let expiresAtString = formatter.string(from: expiresAt)
                
                struct InsertToken: Encodable {
                    let store_id: String
                    let visits: Int
                    let description: String
                    let expires_at: String
                    let created_by: UUID
                    let is_multi_use: Bool
                }
                
                struct TokenResponse: Decodable {
                    let id: String
                }
                
                let storeId = SupabaseManager.shared.storeId ?? Configuration.storeId
                
                let insertData = InsertToken(
                    store_id: storeId,
                    visits: 1,
                    description: "Consumo en Caja",
                    expires_at: expiresAtString,
                    created_by: userId,
                    is_multi_use: false
                )
                
                let response: TokenResponse = try await SupabaseManager.shared.client
                    .from("points_tokens")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
                
                let tokenString = response.id
                
                await MainActor.run {
                    self.qrImage = generateQRCode(from: tokenString)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error al obtener token:\n\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // Aumentar la escala para que no se vea borroso al estirarlo
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return nil
    }
}
