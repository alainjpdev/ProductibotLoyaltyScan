import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @State private var isAppleLoading = false
    @State private var currentNonce: String?
    @State private var errorMessage: String?
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    private var isFormFilled: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Fondo Uber Pure Black
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header Brand Uber Style
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(white: 0.10))
                                    .frame(width: 54, height: 54)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(white: 0.20), lineWidth: 1)
                                    )
                                
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(red: 0.02, green: 0.76, blue: 0.40)) // Uber Green #06C167
                                    .frame(width: 7, height: 7)
                                Text("TERMINAL")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(Color(white: 0.8))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(white: 0.12))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color(white: 0.20), lineWidth: 0.8)
                            )
                        }
                        .padding(.top, 24)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Top Scan")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(-0.8)
                            
                            Text("Inicia sesión para escanear y validar tarjetas")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(white: 0.55))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Banner Uber Style
                    if let error = errorMessage {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(Color(red: 0.95, green: 0.25, blue: 0.25))
                                .font(.system(size: 16))
                                .padding(.top, 1)
                            
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(red: 0.16, green: 0.04, blue: 0.04))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.95, green: 0.25, blue: 0.25).opacity(0.35), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Botones de Autenticación Social Uber Style
                    VStack(spacing: 12) {
                        // Apple Sign-In
                        ZStack {
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    let nonce = AuthHelper.randomNonceString()
                                    currentNonce = nonce
                                    request.requestedScopes = [.fullName, .email]
                                    request.nonce = AuthHelper.sha256(nonce)
                                },
                                onCompletion: handleAppleCompletion
                            )
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 52)
                            .cornerRadius(12)
                            .disabled(isAppleLoading || isGoogleLoading || isLoading)
                            
                            if isAppleLoading {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    )
                                    .frame(height: 52)
                            }
                        }
                        
                        // Google Sign-In
                        Button(action: loginWithGoogle) {
                            HStack(spacing: 12) {
                                if isGoogleLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    GoogleLogoView(size: 19)
                                    Text("Continuar con Google")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(white: 0.10))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(white: 0.22), lineWidth: 1)
                            )
                        }
                        .disabled(isGoogleLoading || isAppleLoading || isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    
                    // Divisor Uber Minimalist
                    HStack(spacing: 14) {
                        Rectangle()
                            .fill(Color(white: 0.16))
                            .frame(height: 1)
                        
                        Text("o ingresa con correo")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(white: 0.45))
                        
                        Rectangle()
                            .fill(Color(white: 0.16))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 22)
                    
                    // Campos de Entrada (Uber Minimalist Inputs)
                    VStack(spacing: 14) {
                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CORREO ELECTRÓNICO")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.6)
                                .foregroundColor(Color(white: 0.55))
                            
                            TextField("nombre@ejemplo.com", text: $email)
                                .focused($focusedField, equals: .email)
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .medium))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .keyboardType(.emailAddress)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color(white: 0.08))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .email ? Color.white : Color(white: 0.18), lineWidth: 1.2)
                                )
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CONTRASEÑA")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.6)
                                .foregroundColor(Color(white: 0.55))
                            
                            HStack(spacing: 10) {
                                Group {
                                    if showPassword {
                                        TextField("Tu contraseña", text: $password)
                                    } else {
                                        SecureField("Tu contraseña", text: $password)
                                    }
                                }
                                .focused($focusedField, equals: .password)
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .medium))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(white: 0.5))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .password ? Color.white : Color(white: 0.18), lineWidth: 1.2)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Botón Principal Iniciar Sesión (Uber Pure White Pill Button)
                    Button(action: login) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("Iniciar Sesión")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isFormFilled ? Color.white : Color(white: 0.22))
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || isGoogleLoading || isAppleLoading || !isFormFilled)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Footer
                    HStack {
                        Spacer()
                        Text("Top Scan • Tarjeta Top")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(white: 0.35))
                        Spacer()
                    }
                    .padding(.top, 36)
                    .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(SupabaseManager.shared.$authErrorMessage) { newMsg in
            if let msg = newMsg {
                self.errorMessage = msg
            }
        }
    }
    
    // MARK: - Acciones de Autenticación
    private func login() {
        focusedField = nil
        isLoading = true
        errorMessage = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signIn(email: cleanEmail, password: password)
                try await SupabaseManager.shared.verifyAdminAndFetchStoreDetails()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func loginWithGoogle() {
        focusedField = nil
        isGoogleLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await SupabaseManager.shared.signInWithGoogle()
                await MainActor.run {
                    isGoogleLoading = false
                }
            } catch {
                await MainActor.run {
                    let nsError = error as NSError
                    if !(nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && nsError.code == 1) {
                        errorMessage = error.localizedDescription
                    }
                    isGoogleLoading = false
                }
            }
        }
    }
    
    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityTokenData, encoding: .utf8),
                  let rawNonce = currentNonce else {
                errorMessage = "No se pudieron obtener las credenciales de Apple."
                return
            }
            
            var fullName: String? = nil
            if let nameComponents = appleIDCredential.fullName {
                let formatter = PersonNameComponentsFormatter()
                let formatted = formatter.string(from: nameComponents).trimmingCharacters(in: .whitespaces)
                if !formatted.isEmpty {
                    fullName = formatted
                }
            }
            
            isAppleLoading = true
            errorMessage = nil
            
            Task {
                do {
                    try await SupabaseManager.shared.signInWithApple(
                        idToken: idTokenString,
                        rawNonce: rawNonce,
                        fullName: fullName
                    )
                    await MainActor.run {
                        isAppleLoading = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isAppleLoading = false
                    }
                }
            }
            
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }
}
