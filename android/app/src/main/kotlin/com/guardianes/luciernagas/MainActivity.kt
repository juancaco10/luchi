package com.guardianes.luciernagas

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Canal nativo que expone las capacidades reales de hardware del
/// dispositivo (ver `lib/core/device/device_capabilities.dart`).
///
/// Se consulta con `PackageManager.hasSystemFeature`, la misma fuente que
/// usa Google Play para filtrar dispositivos — así el comportamiento en
/// runtime coincide con lo que el manifiesto ya declaró opcional
/// (ver AndroidManifest.xml, bloque de `uses-feature`). No se infiere nada
/// por tamaño de pantalla: eso es responsabilidad del lado Dart para
/// clasificar teléfono/tablet, no para saber si hay cámara o GPS.
class MainActivity : FlutterActivity() {
    private val channelName = "luchi/device_capabilities"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "get") {
                    result.success(readCapabilities())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun readCapabilities(): Map<String, Boolean> {
        val pm = packageManager
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        val isTelevisionUiMode =
            uiModeManager?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
        val isTelevision =
            pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK) || isTelevisionUiMode

        val playServicesAvailable =
            GoogleApiAvailability.getInstance()
                .isGooglePlayServicesAvailable(this) == ConnectionResult.SUCCESS

        return mapOf(
            "hasCamera" to pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY),
            "hasGps" to pm.hasSystemFeature(PackageManager.FEATURE_LOCATION_GPS),
            "hasNetworkLocation" to pm.hasSystemFeature(PackageManager.FEATURE_LOCATION_NETWORK),
            "hasMicrophone" to pm.hasSystemFeature(PackageManager.FEATURE_MICROPHONE),
            "hasTouchscreen" to pm.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN),
            "isTelevision" to isTelevision,
            "hasPlayServices" to playServicesAvailable,
        )
    }
}
