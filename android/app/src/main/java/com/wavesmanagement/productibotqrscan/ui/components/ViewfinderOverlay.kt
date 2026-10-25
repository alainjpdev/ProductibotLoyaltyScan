package com.wavesmanagement.productibotqrscan.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wavesmanagement.productibotqrscan.ui.theme.AccentCyan
import com.wavesmanagement.productibotqrscan.ui.theme.TextPrimary

@Composable
fun ViewfinderOverlay(modifier: Modifier = Modifier) {
    val infiniteTransition = rememberInfiniteTransition(label = "laser")
    val laserFraction by infiniteTransition.animateFloat(
        initialValue = -1f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "laser_y"
    )

    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        // Cuadro central del Viewfinder
        Box(
            modifier = Modifier.size(260.dp),
            contentAlignment = Alignment.Center
        ) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                val boxSize = size.width
                val cornerLength = 36.dp.toPx()
                val cornerRadius = 16.dp.toPx()
                val strokeWidth = 4.dp.toPx()
                val cornerColor = Color(0xFF3399FF)

                // Marco sutil
                drawRoundRect(
                    color = Color.White.copy(alpha = 0.15f),
                    size = size,
                    cornerRadius = CornerRadius(cornerRadius, cornerRadius),
                    style = Stroke(width = 1.dp.toPx())
                )

                // Top-Left corner
                val pathTL = Path().apply {
                    moveTo(0f, cornerLength)
                    lineTo(0f, cornerRadius)
                    quadraticTo(0f, 0f, cornerRadius, 0f)
                    lineTo(cornerLength, 0f)
                }
                drawPath(pathTL, cornerColor, style = Stroke(strokeWidth))

                // Top-Right corner
                val pathTR = Path().apply {
                    moveTo(boxSize - cornerLength, 0f)
                    lineTo(boxSize - cornerRadius, 0f)
                    quadraticTo(boxSize, 0f, boxSize, cornerRadius)
                    lineTo(boxSize, cornerLength)
                }
                drawPath(pathTR, cornerColor, style = Stroke(strokeWidth))

                // Bottom-Right corner
                val pathBR = Path().apply {
                    moveTo(boxSize, boxSize - cornerLength)
                    lineTo(boxSize, boxSize - cornerRadius)
                    quadraticTo(boxSize, boxSize, boxSize - cornerRadius, boxSize)
                    lineTo(boxSize - cornerLength, boxSize)
                }
                drawPath(pathBR, cornerColor, style = Stroke(strokeWidth))

                // Bottom-Left corner
                val pathBL = Path().apply {
                    moveTo(cornerLength, boxSize)
                    lineTo(cornerRadius, boxSize)
                    quadraticTo(0f, boxSize, 0f, boxSize - cornerRadius)
                    lineTo(0f, boxSize - cornerLength)
                }
                drawPath(pathBL, cornerColor, style = Stroke(strokeWidth))

                // Línea láser animada
                val laserY = (boxSize / 2f) + (laserFraction * (boxSize / 2f - 20f))
                val laserBrush = Brush.horizontalGradient(
                    colors = listOf(
                        Color.Transparent,
                        AccentCyan.copy(alpha = 0.9f),
                        AccentCyan,
                        AccentCyan.copy(alpha = 0.9f),
                        Color.Transparent
                    )
                )
                drawLine(
                    brush = laserBrush,
                    start = Offset(15f, laserY),
                    end = Offset(boxSize - 15f, laserY),
                    strokeWidth = 3.dp.toPx()
                )
            }
        }

        // Indicador inferior
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 80.dp)
                .clip(CircleShape)
                .background(Color(0xCC121724))
                .padding(horizontal = 20.dp, vertical = 12.dp)
        ) {
            Text(
                text = "Apunta al código QR del cliente o cupón",
                color = TextPrimary.copy(alpha = 0.9f),
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium
            )
        }
    }
}
