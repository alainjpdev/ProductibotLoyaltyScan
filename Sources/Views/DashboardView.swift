import SwiftUI

struct DashboardView: View {
    @State private var isLoggingOut = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if let storeName = SupabaseManager.shared.storeName {
                    Text(storeName)
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 10)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Cargando...")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                }
                
                NavigationLink(destination: ScanQRView()) {
                    VStack(spacing: 15) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                        Text("Escanear QR de Cliente")
                            .font(.title2)
                            .bold()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                
                NavigationLink(destination: GenerateQRView()) {
                    VStack(spacing: 15) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 60))
                        Text("Generar QR para Mesa")
                            .font(.title2)
                            .bold()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                
                Spacer()
            }
            .padding(30)
            .navigationTitle("Staff Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: logout) {
                        if isLoggingOut {
                            ProgressView()
                        } else {
                            Text("Salir")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isLoggingOut)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func logout() {
        isLoggingOut = true
        Task {
            do {
                try await SupabaseManager.shared.signOut()
            } catch {
                print("Error signing out: \(error)")
                isLoggingOut = false
            }
        }
    }
}
