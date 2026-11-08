package com.wavesmanagement.productibotqrscan

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.Crossfade
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.wavesmanagement.productibotqrscan.data.SupabaseManager
import com.wavesmanagement.productibotqrscan.ui.screens.DashboardScreen
import com.wavesmanagement.productibotqrscan.ui.screens.LoginScreen
import com.wavesmanagement.productibotqrscan.ui.screens.ScannerScreen
import com.wavesmanagement.productibotqrscan.ui.theme.ProductibotLoyaltyScanTheme
import io.github.jan.supabase.auth.handleDeeplinks

class MainActivity : ComponentActivity() {

    private var onCameraPermissionGranted: (() -> Unit)? = null

    private val cameraPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            onCameraPermissionGranted?.invoke()
        } else {
            Toast.makeText(
                this,
                "Se requiere permiso de cámara para escanear códigos QR.",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        try {
            val supabase = SupabaseManager.getInstance()
            supabase.client.handleDeeplinks(intent)
        } catch (e: Exception) {
            // Logger o fallback
        }

        setContent {
            ProductibotLoyaltyScanTheme {
                val supabase = remember { SupabaseManager.getInstance() }
                val isAuthenticated by supabase.isAuthenticated.collectAsStateWithLifecycle()
                var isScannerPresented by remember { mutableStateOf(false) }

                fun requestCameraAndOpenScanner() {
                    val hasCam = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.CAMERA
                    ) == PackageManager.PERMISSION_GRANTED

                    if (hasCam) {
                        isScannerPresented = true
                    } else {
                        onCameraPermissionGranted = {
                            isScannerPresented = true
                        }
                        cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
                    }
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color.Black
                ) {
                    Crossfade(
                        targetState = isAuthenticated,
                        label = "auth_crossfade"
                    ) { loggedIn ->
                        if (loggedIn) {
                            if (isScannerPresented) {
                                ScannerScreen(
                                    onDismiss = { isScannerPresented = false }
                                )
                            } else {
                                DashboardScreen(
                                    onOpenScanner = { requestCameraAndOpenScanner() }
                                )
                            }
                        } else {
                            LoginScreen()
                        }
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        try {
            val supabase = SupabaseManager.getInstance()
            supabase.client.handleDeeplinks(intent)
        } catch (e: Exception) {
            // Fallback
        }
    }
}
