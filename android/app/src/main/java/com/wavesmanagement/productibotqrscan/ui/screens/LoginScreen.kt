package com.wavesmanagement.productibotqrscan.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.wavesmanagement.productibotqrscan.data.SupabaseManager
import com.wavesmanagement.productibotqrscan.ui.components.AppleLogo
import com.wavesmanagement.productibotqrscan.ui.components.GoogleLogo
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(
    modifier: Modifier = Modifier
) {
    val supabase = remember { SupabaseManager.getInstance() }
    val scope = rememberCoroutineScope()
    val focusManager = LocalFocusManager.current

    val managerAuthError by supabase.authErrorMessage.collectAsStateWithLifecycle()

    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var isGoogleLoading by remember { mutableStateOf(false) }
    var isAppleLoading by remember { mutableStateOf(false) }
    var localError by remember { mutableStateOf<String?>(null) }

    val displayError = localError ?: managerAuthError

    fun doLogin() {
        if (email.isBlank() || password.isBlank() || isLoading) return
        isLoading = true
        localError = null
        supabase.setAuthErrorMessage(null)
        focusManager.clearFocus()

        scope.launch {
            try {
                supabase.signIn(email.trim(), password)
            } catch (e: Exception) {
                localError = e.localizedMessage ?: "Error al iniciar sesión. Verifica tus credenciales."
            } finally {
                isLoading = false
            }
        }
    }

    fun doGoogleLogin() {
        if (isGoogleLoading || isLoading || isAppleLoading) return
        isGoogleLoading = true
        localError = null
        supabase.setAuthErrorMessage(null)

        scope.launch {
            try {
                supabase.signInWithGoogle()
            } catch (e: Exception) {
                localError = e.localizedMessage ?: "Error al iniciar sesión con Google."
            } finally {
                isGoogleLoading = false
            }
        }
    }

    fun doAppleLogin() {
        if (isAppleLoading || isLoading || isGoogleLoading) return
        isAppleLoading = true
        localError = null
        supabase.setAuthErrorMessage(null)

        scope.launch {
            try {
                supabase.signInWithApple()
            } catch (e: Exception) {
                localError = e.localizedMessage ?: "Error al iniciar sesión con Apple."
            } finally {
                isAppleLoading = false
            }
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(top = 28.dp, bottom = 32.dp),
            horizontalAlignment = Alignment.Start,
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Header Brand Uber Style
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(54.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .background(Color(0xFF1A1A1A))
                        .border(1.dp, Color(0xFF333333), RoundedCornerShape(14.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.QrCodeScanner,
                        contentDescription = "Logo QR",
                        tint = Color.White,
                        modifier = Modifier.size(28.dp)
                    )
                }

                // Terminal status capsule
                Row(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(Color(0xFF1E1E1E))
                        .border(0.8.dp, Color(0xFF333333), CircleShape)
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(7.dp)
                            .background(Color(0xFF06C167), CircleShape)
                    )
                    Text(
                        text = "TERMINAL",
                        color = Color(0xFFCCCCCC),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
            }

            // Titles
            Column(
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = "Top Scan",
                    color = Color.White,
                    fontSize = 34.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = (-0.8).sp
                )
                Text(
                    text = "Inicia sesión para escanear y validar tarjetas",
                    color = Color(0xFF8C8C8C),
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Normal
                )
            }

            // Error Banner Uber Style
            AnimatedVisibility(
                visible = displayError != null,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                displayError?.let { msg ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFF280A0A))
                            .border(1.dp, Color(0xFFF24040).copy(alpha = 0.35f), RoundedCornerShape(12.dp))
                            .padding(14.dp),
                        verticalAlignment = Alignment.Top,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Error,
                            contentDescription = null,
                            tint = Color(0xFFF24040),
                            modifier = Modifier
                                .size(16.dp)
                                .padding(top = 2.dp)
                        )
                        Text(
                            text = msg,
                            color = Color.White,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            // Botones de Autenticación Social Uber Style
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Botón Sign In with Apple (Uber Pure White Pill)
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.White)
                        .clickable(enabled = !isAppleLoading && !isGoogleLoading && !isLoading) {
                            doAppleLogin()
                        },
                    contentAlignment = Alignment.Center
                ) {
                    if (isAppleLoading) {
                        CircularProgressIndicator(
                            color = Color.Black,
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            AppleLogo(modifier = Modifier.size(17.dp), tint = Color.Black)
                            Text(
                                text = "Sign in with Apple",
                                color = Color.Black,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }

                // Botón Continuar con Google (Uber Dark Card)
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color(0xFF161616))
                        .border(1.dp, Color(0xFF2E2E2E), RoundedCornerShape(12.dp))
                        .clickable(enabled = !isGoogleLoading && !isAppleLoading && !isLoading) {
                            doGoogleLogin()
                        },
                    contentAlignment = Alignment.Center
                ) {
                    if (isGoogleLoading) {
                        CircularProgressIndicator(
                            color = Color.White,
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            GoogleLogo(modifier = Modifier.size(17.dp))
                            Text(
                                text = "Continuar con Google",
                                color = Color.White,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }

            // Divisor "o ingresa con correo"
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                HorizontalDivider(
                    modifier = Modifier.weight(1f),
                    color = Color(0xFF222222),
                    thickness = 1.dp
                )
                Text(
                    text = "o ingresa con correo",
                    color = Color(0xFF6E6E6E),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                )
                HorizontalDivider(
                    modifier = Modifier.weight(1f),
                    color = Color(0xFF222222),
                    thickness = 1.dp
                )
            }

            // Campos de Entrada Uber Style
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Email Field
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = "CORREO ELECTRÓNICO",
                        color = Color(0xFF8C8C8C),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 0.6.sp
                    )
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        placeholder = {
                            Text("nombre@ejemplo.com", color = Color(0xFF555555))
                        },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Email,
                            imeAction = ImeAction.Next
                        ),
                        keyboardActions = KeyboardActions(
                            onNext = { focusManager.moveFocus(FocusDirection.Down) }
                        ),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedContainerColor = Color(0xFF141414),
                            unfocusedContainerColor = Color(0xFF141414),
                            focusedBorderColor = Color.White,
                            unfocusedBorderColor = Color(0xFF2E2E2E),
                            cursorColor = Color.White
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                // Password Field
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = "CONTRASEÑA",
                        color = Color(0xFF8C8C8C),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 0.6.sp
                    )
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        placeholder = {
                            Text("Tu contraseña", color = Color(0xFF555555))
                        },
                        trailingIcon = {
                            IconButton(onClick = { showPassword = !showPassword }) {
                                Icon(
                                    imageVector = if (showPassword) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                    contentDescription = if (showPassword) "Ocultar" else "Mostrar",
                                    tint = Color(0xFF808080),
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        },
                        visualTransformation = if (showPassword) VisualTransformation.None else PasswordVisualTransformation(),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Done
                        ),
                        keyboardActions = KeyboardActions(
                            onDone = { doLogin() }
                        ),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedContainerColor = Color(0xFF141414),
                            unfocusedContainerColor = Color(0xFF141414),
                            focusedBorderColor = Color.White,
                            unfocusedBorderColor = Color(0xFF2E2E2E),
                            cursorColor = Color.White
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }

            // Botón Principal Iniciar Sesión (Uber Pure White Button)
            val isFormFilled = email.isNotBlank() && password.isNotBlank()
            val isButtonEnabled = !isLoading && !isGoogleLoading && !isAppleLoading && isFormFilled

            Button(
                onClick = { doLogin() },
                enabled = isButtonEnabled,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isFormFilled) Color.White else Color(0xFF383838),
                    disabledContainerColor = Color(0xFF383838)
                ),
                contentPadding = PaddingValues()
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        color = Color.Black,
                        modifier = Modifier.size(22.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        text = "Iniciar Sesión",
                        color = if (isFormFilled) Color.Black else Color(0xFF888888),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            // Footer
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Top Scan • Tarjeta Top",
                    color = Color(0xFF555555),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}
