package com.wavesmanagement.productibotqrscan.ui.screens

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.wavesmanagement.productibotqrscan.data.SupabaseManager
import com.wavesmanagement.productibotqrscan.data.model.ScanProcessResult
import com.wavesmanagement.productibotqrscan.data.model.ScanResultType
import com.wavesmanagement.productibotqrscan.ui.components.ResultModal
import com.wavesmanagement.productibotqrscan.ui.components.ViewfinderOverlay
import com.wavesmanagement.productibotqrscan.ui.theme.CardDark
import kotlinx.coroutines.launch
import java.util.concurrent.Executors

@Composable
fun ScannerScreen(
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val supabase = remember { SupabaseManager.getInstance() }
    val scope = rememberCoroutineScope()

    var cameraControl by remember { mutableStateOf<CameraControl?>(null) }
    var isTorchOn by remember { mutableStateOf(false) }
    var isProcessing by remember { mutableStateOf(false) }
    var scanResult by remember { mutableStateOf<ScanProcessResult?>(null) }

    // Flag para pausar análisis mientras se muestra el resultado
    var canScan by remember { mutableStateOf(true) }

    fun playBeepAndVibrate(isError: Boolean = false) {
        try {
            // Sonido Beep agudo
            val toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 90)
            toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
        } catch (e: Exception) {
            Log.e("ScannerScreen", "Tone error: ${e.message}")
        }

        try {
            // Vibración háptica
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = if (isError) {
                    VibrationEffect.createWaveform(longArrayOf(0, 100, 80, 100), -1)
                } else {
                    VibrationEffect.createOneShot(80, VibrationEffect.DEFAULT_AMPLITUDE)
                }
                vibrator.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(80)
            }
        } catch (e: Exception) {
            Log.e("ScannerScreen", "Vibrate error: ${e.message}")
        }
    }

    fun handleScannedCode(code: String) {
        if (!canScan || isProcessing || scanResult != null) return
        canScan = false
        isProcessing = true
        playBeepAndVibrate()

        scope.launch {
            val res = supabase.processScannedCode(code)
            isProcessing = false
            scanResult = res
            if (res.type == ScanResultType.ERROR) {
                playBeepAndVibrate(isError = true)
            }
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        // 1. Camera Preview
        AndroidView(
            factory = { ctx ->
                val previewView = PreviewView(ctx).apply {
                    scaleType = PreviewView.ScaleType.FILL_CENTER
                }
                val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                val executor = ContextCompat.getMainExecutor(ctx)
                val analysisExecutor = Executors.newSingleThreadExecutor()

                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder().build().also {
                        it.setSurfaceProvider(previewView.surfaceProvider)
                    }

                    val barcodeScanner = BarcodeScanning.getClient()

                    val imageAnalysis = ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .build()

                    imageAnalysis.setAnalyzer(analysisExecutor) { imageProxy ->
                        @SuppressLint("UnsafeOptInUsageError")
                        val mediaImage = imageProxy.image
                        if (mediaImage != null && canScan) {
                            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
                            barcodeScanner.process(image)
                                .addOnSuccessListener { barcodes ->
                                    for (barcode in barcodes) {
                                        if (barcode.format == Barcode.FORMAT_QR_CODE) {
                                            barcode.rawValue?.let { raw ->
                                                handleScannedCode(raw)
                                            }
                                            break
                                        }
                                    }
                                }
                                .addOnCompleteListener {
                                    imageProxy.close()
                                }
                        } else {
                            imageProxy.close()
                        }
                    }

                    try {
                        cameraProvider.unbindAll()
                        val camera = cameraProvider.bindToLifecycle(
                            lifecycleOwner,
                            CameraSelector.DEFAULT_BACK_CAMERA,
                            preview,
                            imageAnalysis
                        )
                        cameraControl = camera.cameraControl
                    } catch (e: Exception) {
                        Log.e("ScannerScreen", "Camera bind failed: ${e.message}")
                    }
                }, executor)

                previewView
            },
            modifier = Modifier.fillMaxSize()
        )

        // 2. Retícula del Viewfinder con Láser
        ViewfinderOverlay()

        // 3. Barra Superior (Cerrar y Linterna)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 44.dp)
                .align(Alignment.TopCenter),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Botón Cerrar
            Row(
                modifier = Modifier
                    .clip(CircleShape)
                    .background(Color(0x99121724))
                    .clickable { onDismiss() }
                    .padding(horizontal = 16.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Cerrar",
                    tint = Color.White,
                    modifier = Modifier.size(18.dp)
                )
                Text(
                    text = "Cerrar",
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            // Botón Linterna
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(Color(0x99121724))
                    .clickable {
                        isTorchOn = !isTorchOn
                        cameraControl?.enableTorch(isTorchOn)
                    },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (isTorchOn) Icons.Default.FlashOn else Icons.Default.FlashOff,
                    contentDescription = "Linterna",
                    tint = if (isTorchOn) Color(0xFFFFD600) else Color.White,
                    modifier = Modifier.size(20.dp)
                )
            }
        }

        // 4. Overlay de Procesamiento con Supabase
        if (isProcessing) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.65f)),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(CardDark)
                        .padding(28.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    CircularProgressIndicator(
                        color = Color.White,
                        modifier = Modifier.size(40.dp),
                        strokeWidth = 3.dp
                    )
                    Text(
                        text = "Validando en el sistema...",
                        color = Color.White,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }

        // 5. Modal de Resultado (Visita, Premio o Error)
        scanResult?.let { result ->
            ResultModal(
                result = result,
                onScanAnother = {
                    scanResult = null
                    canScan = true
                },
                onFinish = {
                    onDismiss()
                }
            )
        }
    }
}
