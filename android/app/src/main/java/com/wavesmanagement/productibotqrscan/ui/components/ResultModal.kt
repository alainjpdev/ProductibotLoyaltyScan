package com.wavesmanagement.productibotqrscan.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wavesmanagement.productibotqrscan.data.model.ScanProcessResult
import com.wavesmanagement.productibotqrscan.data.model.ScanResultType
import com.wavesmanagement.productibotqrscan.ui.theme.*

@Composable
fun ResultModal(
    result: ScanProcessResult,
    onScanAnother: () -> Unit,
    onFinish: () -> Unit,
    modifier: Modifier = Modifier
) {
    val (icon, tintColor, bgColor) = when (result.type) {
        ScanResultType.VISIT -> Triple(Icons.Default.CheckCircle, SuccessGreen, SuccessGreenBg)
        ScanResultType.REWARD -> Triple(Icons.Default.CardGiftcard, RewardYellow, RewardYellowBg)
        ScanResultType.ERROR -> Triple(Icons.Default.Error, ErrorRed, ErrorRedBg)
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.75f)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = 340.dp)
                .fillMaxWidth(0.9f)
                .clip(RoundedCornerShape(24.dp))
                .background(CardDark)
                .border(1.5.dp, tintColor.copy(alpha = 0.4f), RoundedCornerShape(24.dp))
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Ícono de estado
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .clip(CircleShape)
                    .background(bgColor),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = tintColor,
                    modifier = Modifier.size(44.dp)
                )
            }

            // Título
            Text(
                text = result.title,
                color = TextPrimary,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )

            // Nombre del cliente
            if (!result.clientName.isNullOrBlank()) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        tint = AccentCyan,
                        modifier = Modifier.size(18.dp)
                    )
                    Text(
                        text = result.clientName,
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            // Subtítulo
            Text(
                text = result.subtitle,
                color = TextSecondary,
                fontSize = 15.sp,
                textAlign = TextAlign.Center
            )

            // Detalle adicional
            if (!result.detail.isNullOrBlank()) {
                Text(
                    text = result.detail,
                    color = TextMuted,
                    fontSize = 13.sp,
                    textAlign = TextAlign.Center
                )
            }

            HorizontalDivider(color = BorderSubtle, thickness = 1.dp)

            // Botón Escanear Otro
            Button(
                onClick = onScanAnother,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent),
                contentPadding = PaddingValues()
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.horizontalGradient(
                                colors = listOf(AccentBlue, AccentBlueDark)
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.QrCodeScanner,
                            contentDescription = null,
                            tint = Color.White
                        )
                        Text(
                            text = "Escanear Otro",
                            color = Color.White,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            // Botón Terminar
            TextButton(
                onClick = onFinish,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = "Terminar",
                    color = TextSecondary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}
