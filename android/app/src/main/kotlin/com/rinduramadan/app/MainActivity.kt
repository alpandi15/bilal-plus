package com.rinduramadan.app

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bilalplus/haptics")
            .setMethodCallHandler { call, result ->
                if (call.method == "vibrate") {
                    result.success(vibrate(call.arguments as? String ?: "tap"))
                } else {
                    result.notImplemented()
                }
            }
        // versi aplikasi, buka tautan, & halaman info aplikasi (izin launcher)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bilalplus/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "appVersion" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        result.success(info.versionName)
                    }
                    "openUrl" -> result.success(
                        start(Intent(Intent.ACTION_VIEW, Uri.parse(call.arguments as String))),
                    )
                    "openAppSettings" -> result.success(
                        start(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            ),
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun start(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }

    /**
     * Getar langsung lewat Vibrator - HapticFeedback bawaan Flutter
     * (performHapticFeedback) ikut setelan "getaran sentuh" sistem dan
     * diabaikan di banyak ponsel (mis. Xiaomi/HyperOS). Lihat
     * lib/services/haptics.dart untuk arti tiap pola.
     */
    private fun vibrate(kind: String): Boolean {
        val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
        if (vibrator == null || !vibrator.hasVibrator()) return false

        // jeda, getar, jeda, getar, ... (ms) & kekuatannya (1..255)
        val (timings, amplitudes) = when (kind) {
            // satu ketukan hitung: pendek & tajam
            "tap" -> longArrayOf(0, 24) to intArrayOf(0, 180)
            // hitungan satu dzikir tercapai: dua denyut kuat
            "target" -> longArrayOf(0, 70, 90, 70) to intArrayOf(0, 255, 0, 255)
            // semua dzikir selesai: tiga denyut naik lalu panjang
            "complete" -> longArrayOf(0, 40, 70, 40, 70, 60, 90, 220) to
                intArrayOf(0, 120, 0, 180, 0, 230, 0, 255)
            // atur ulang / nyalakan getar
            else -> longArrayOf(0, 35) to intArrayOf(0, 200)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.cancel()
            val effect = if (vibrator.hasAmplitudeControl()) {
                VibrationEffect.createWaveform(timings, amplitudes, -1)
            } else {
                VibrationEffect.createWaveform(timings, -1)
            }
            // jenis getar eksplisit: tanpa ini Android 13+ menggolongkan getar
            // pendek sebagai TOUCH, yang mati bila "getaran sentuh" sistem
            // dimatikan - padahal getar tasbih dinyalakan sendiri di aplikasi
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                vibrator.vibrate(
                    effect,
                    VibrationAttributes.createForUsage(VibrationAttributes.USAGE_MEDIA),
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(
                    effect,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
            }
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(timings, -1)
        }
        return true
    }
}
