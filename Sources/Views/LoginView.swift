import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            // Fondo oscuro estilizado
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.14),
                    Color(red: 0.04, green: 0.05, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Halo de luz ambiente
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(y: -120)
            
            ScrollView {
                VStack(spacing: 28) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Logo e Identidad
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                                )
                            
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 42, weight: .light))
                                .foregroundColor(.cyan)
                        }
                        .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 5)
                        
                        VStack(spacing: 6) {
                            Text("Productibot QR SCAN")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Terminal de Escaneo para Personal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Mensaje de Error
                    if let error = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Campos de Entrada
                    VStack(spacing: 16) {
                        // Email Field
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(width: 20)
                            
                            TextField("", text: $email, prompt: Text("Correo electrónico").foregroundColor(.white.opacity(0.35)))
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .keyboardType(.emailAddress)
                        }
                        .padding(16)
                        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        
                        // Password Field
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(width: 20)
                            
                            Group {
                                if showPassword {
                                    TextField("", text: $password, prompt: Text("Contraseña").foregroundColor(.white.opacity(0.35)))
                                } else {
                                    SecureField("", text: $password, prompt: Text("Contraseña").foregroundColor(.white.opacity(0.35)))
                                }
                            }
                            .foregroundColor(.white)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            
                            Button(action: {
                                withAnimation {
                                    showPassword.toggle()
                                }
                            }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding(16)
                        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Botón de Iniciar Sesión
                    Button(action: login) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Iniciar Sesión")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.45, blue: 0.95),
                                    Color(red: 0.08, green: 0.28, blue: 0.75)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.blue.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
                    .disabled(isLoading || email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
                    .opacity(isLoading || email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty ? 0.5 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func login() {
        isLoading = true
        errorMessage = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signIn(email: cleanEmail, password: password)
                await MainActor.run {
                    SupabaseManager.shared.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
