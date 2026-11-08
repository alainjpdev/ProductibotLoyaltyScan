package com.wavesmanagement.productibotqrscan.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

@Composable
fun GoogleLogo(modifier: Modifier = Modifier.size(18.dp)) {
    Canvas(modifier = modifier) {
        val w = size.width
        val h = size.height
        val strokeW = w * 0.22f
        val radius = (w - strokeW) / 2f
        val center = Offset(w / 2f, h / 2f)
        val arcRect = Rect(
            center.x - radius,
            center.y - radius,
            center.x + radius,
            center.y + radius
        )

        val red = Color(0xFFEA4335)
        val yellow = Color(0xFFFBBC05)
        val green = Color(0xFF34A853)
        val blue = Color(0xFF4285F4)

        // Arcs
        drawArc(
            color = red,
            startAngle = 195f,
            sweepAngle = 110f,
            useCenter = false,
            topLeft = arcRect.topLeft,
            size = arcRect.size,
            style = Stroke(width = strokeW)
        )
        drawArc(
            color = yellow,
            startAngle = 125f,
            sweepAngle = 70f,
            useCenter = false,
            topLeft = arcRect.topLeft,
            size = arcRect.size,
            style = Stroke(width = strokeW)
        )
        drawArc(
            color = green,
            startAngle = 35f,
            sweepAngle = 90f,
            useCenter = false,
            topLeft = arcRect.topLeft,
            size = arcRect.size,
            style = Stroke(width = strokeW)
        )
        drawArc(
            color = blue,
            startAngle = -25f,
            sweepAngle = 60f,
            useCenter = false,
            topLeft = arcRect.topLeft,
            size = arcRect.size,
            style = Stroke(width = strokeW)
        )

        // Blue Horizontal Bar
        val barPath = Path().apply {
            moveTo(center.x, center.y - strokeW / 2f)
            lineTo(w, center.y - strokeW / 2f)
            lineTo(w, center.y + strokeW / 2f)
            lineTo(center.x, center.y + strokeW / 2f)
            close()
        }
        drawPath(barPath, blue, style = Fill)
    }
}

@Composable
fun AppleLogo(
    modifier: Modifier = Modifier.size(18.dp),
    tint: Color = Color.Black
) {
    Canvas(modifier = modifier) {
        val w = size.width
        val h = size.height

        // Apple body and leaf drawn proportionally
        val bodyPath = Path().apply {
            moveTo(w * 0.5f, h * 0.28f)
            cubicTo(w * 0.42f, h * 0.28f, w * 0.35f, h * 0.32f, w * 0.28f, h * 0.32f)
            cubicTo(w * 0.17f, h * 0.32f, w * 0.05f, h * 0.42f, w * 0.05f, h * 0.62f)
            cubicTo(w * 0.05f, h * 0.77f, w * 0.16f, h * 0.95f, w * 0.28f, h * 0.95f)
            cubicTo(w * 0.35f, h * 0.95f, w * 0.40f, h * 0.90f, w * 0.50f, h * 0.90f)
            cubicTo(w * 0.60f, h * 0.90f, w * 0.65f, h * 0.95f, w * 0.72f, h * 0.95f)
            cubicTo(w * 0.84f, h * 0.95f, w * 0.95f, h * 0.77f, w * 0.95f, h * 0.62f)
            cubicTo(w * 0.82f, h * 0.57f, w * 0.82f, h * 0.38f, w * 0.95f, h * 0.33f)
            cubicTo(w * 0.88f, h * 0.24f, w * 0.76f, h * 0.28f, w * 0.72f, h * 0.28f)
            cubicTo(w * 0.65f, h * 0.28f, w * 0.58f, h * 0.28f, w * 0.50f, h * 0.28f)
            close()
        }
        drawPath(bodyPath, tint, style = Fill)

        val leafPath = Path().apply {
            moveTo(w * 0.50f, h * 0.24f)
            cubicTo(w * 0.55f, h * 0.16f, w * 0.64f, h * 0.05f, w * 0.72f, h * 0.05f)
            cubicTo(w * 0.73f, h * 0.14f, w * 0.68f, h * 0.23f, w * 0.62f, h * 0.27f)
            cubicTo(w * 0.58f, h * 0.30f, w * 0.52f, h * 0.27f, w * 0.50f, h * 0.24f)
            close()
        }
        drawPath(leafPath, tint, style = Fill)
    }
}

