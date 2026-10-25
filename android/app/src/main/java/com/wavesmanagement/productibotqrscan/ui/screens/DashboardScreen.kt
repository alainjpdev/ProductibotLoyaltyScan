package com.wavesmanagement.productibotqrscan.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Error
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.wavesmanagement.productibotqrscan.data.SupabaseManager
import com.wavesmanagement.productibotqrscan.data.model.ScanProcessResult
import com.wavesmanagement.productibotqrscan.data.model.ScanResultType
import com.wavesmanagement.productibotqrscan.ui.components.PulseHeroButton
import com.wavesmanagement.productibotqrscan.ui.theme.*
import kotlinx.coroutines.launch

@Composable
fun DashboardScreen(
    onOpenScanner: () -> Unit,
    modifier: Modifier = Modifier
) {
    val supabase = remember { SupabaseManager.getInstance() }
    val scope = rememberCoroutineScope()

    val storeName by supabase.storeName.collectAsStateWithLifecycle()
    val staffName by supabase.staffName.collectAsStateWithLifecycle()
    val lastScanResult by supabase.lastScanResult.collectAsStateWithLifecycle()

    var showLogoutDialog by remember { mutableStateOf(false) }
    var isLoggingOut by remember { mutableStateOf(false) }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(BgDarkTop, BgDarkBottom)
                )
            )
    ) {
        // Halo de luz ambiental
        Box(
            modifier = Modifier
                .size(320.dp)
                .align(Alignment.Center)
                .offset(y = (-40).dp)
                .blur(70.dp)
                .background(AccentBlue.copy(alpha = 0.12f), shape = CircleShape)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp)
                .padding(top = 48.dp, bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // MARK: - Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = storeName ?: "Productibot Scan",
                        color = Color.White,
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = staffName ?: "Terminal de Escaneo",
                        color = Color.White.copy(alpha = 0.6f),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                // Botón Salir
                Box(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.08f))
                        .border(1.dp, Color.White.copy(alpha = 0.12f), CircleShape)
                        .clickable(enabled = !isLoggingOut) {
                            showLogoutDialog = true
                        }
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                    contentAlignment = Alignment.Center
                ) {
                    if (isLoggingOut) {
                        CircularProgressIndicator(
                            color = Color.White,
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ExitToApp,
                                contentDescription = "Salir",
                                tint = Color.White.copy(alpha = 0.8f),
                                modifier = Modifier.size(14.dp)
                            )
                            Text(
                                text = "Salir",
                                color = Color.White.copy(alpha = 0.8f),
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }

            // MARK: - Botón Central Hero
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(28.dp)
            ) {
                PulseHeroButton(onClick = onOpenScanner)

                // Indicador de estado del sistema (LED verde)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(SuccessGreen)
                    )
                    Text(
                        text = "Listo para escanear tarjetas y cupones",
                        color = Color.White.copy(alpha = 0.65f),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            // MARK: - Tarjeta de Último Escaneo
            AnimatedVisibility(
                visible = lastScanResult != null,
                enter = slideInVertically(initialOffsetY = { it / 2 }) + fadeIn(),
                exit = slideOutVertically() + fadeOut()
            ) {
                lastScanResult?.let { result ->
                    LastScanCard(result = result)
                }
            }
            if (lastScanResult == null) {
                Spacer(modifier = Modifier.height(50.dp))
            }
        }
    }

    // Diálogo de Confirmación de Cierre de Sesión
    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = {
                Text("¿Deseas cerrar sesión?", color = Color.White, fontWeight = FontWeight.Bold)
            },
            text = {
                Text("Tendrás que ingresar nuevamente tus credenciales de empleado para escanear.", color = TextSecondary)
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showLogoutDialog = false
                        isLoggingOut = true
                        scope.launch {
                            try {
                                supabase.signOut()
                            } finally {
                                isLoggingOut = false
                            }
                        }
                    }
                ) {
                    Text("Cerrar Sesión", color = ErrorRed, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text("Cancelar", color = TextSecondary)
                }
            },
            containerColor = CardDark,
            shape = RoundedCornerShape(20.dp)
        )
    }
}

@Composable
fun LastScanCard(
    result: ScanProcessResult,
    modifier: Modifier = Modifier
) {
    val (icon, tintColor, bgColor) = when (result.type) {
        ScanResultType.VISIT -> Triple(Icons.Default.Check, SuccessGreen, SuccessGreenBg)
        ScanResultType.REWARD -> Triple(Icons.Default.CardGiftcard, RewardYellow, RewardYellowBg)
        ScanResultType.ERROR -> Triple(Icons.Default.Error, ErrorRed, ErrorRedBg)
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(CardDark)
            .border(1.dp, BorderSubtle, RoundedCornerShape(16.dp))
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(bgColor),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = tintColor,
                modifier = Modifier.size(20.dp)
            )
        }

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = result.title,
                    color = Color.White,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Reciente",
                    color = Color.White.copy(alpha = 0.5f),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            if (!result.clientName.isNullOrBlank()) {
                Text(
                    text = result.clientName,
                    color = AccentCyan,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Text(
                text = result.subtitle,
                color = Color.White.copy(alpha = 0.75f),
                fontSize = 12.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
