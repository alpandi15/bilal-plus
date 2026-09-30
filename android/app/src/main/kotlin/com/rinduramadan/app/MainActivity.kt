package com.rinduramadan.app

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
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
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        showOverLockScreen(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        showOverLockScreen(intent)
        super.onNewIntent(intent)
    }

    /**
     * Dibuka dari notifikasi adzan layar penuh (payload "alarm|..."): tampil
     * di atas layar kunci & nyalakan layar, seperti aplikasi alarm. Dilepas
     * lagi lewat `clearLockScreen` saat halaman adzan ditutup - di luar itu
     * aplikasi tidak pernah tampil di atas layar kunci.
     */
    private fun showOverLockScreen(intent: Intent?) {
        val payload = intent?.getStringExtra("payload") ?: return
        if (intent.action != "SELECT_NOTIFICATION" || !payload.startsWith("alarm|")) return
        setLockScreenFlags(true)
    }

    private fun setLockScreenFlags(on: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(on)
            setTurnScreenOn(on)
        } else {
            @Suppress("DEPRECATION")
            val flags = android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (on) window.addFlags(flags) else window.clearFlags(flags)
        }
    }

    /** Android 14+: izin "tampilan layar penuh" diberikan pengguna. */
    private fun canFullScreen(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        return nm.canUseFullScreenIntent()
    }
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
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "bilalplus/heading")
            .setStreamHandler(HeadingStream())
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
                    "clearLockScreen" -> {
                        setLockScreenFlags(false)
                        result.success(true)
                    }
                    "canFullScreen" -> result.success(canFullScreen())
                    "openFullScreenSettings" -> result.success(
                        if (Build.VERSION.SDK_INT >= 34) {
                            start(
                                Intent(
                                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                    Uri.fromParts("package", packageName, null),
                                ),
                            )
                        } else {
                            true
                        },
                    )
                    // utara magnetik -> utara sejati di lokasi ini (derajat, timur +)
                    "declination" -> {
                        val lat = call.argument<Double>("lat") ?: 0.0
                        val lon = call.argument<Double>("lon") ?: 0.0
                        val field = GeomagneticField(
                            lat.toFloat(), lon.toFloat(), 0f, System.currentTimeMillis(),
                        )
                        result.success(field.declination.toDouble())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Arah kompas (derajat dari utara magnetik, 0..360) dari sensor rotation
     * vector - dipakai halaman Kiblat. Akurasi sensor ikut dikirim supaya
     * aplikasi bisa meminta kalibrasi (gerakan angka 8).
     */
    private inner class HeadingStream : EventChannel.StreamHandler, SensorEventListener {
        private var sink: EventChannel.EventSink? = null
        private val manager get() = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        private val rotation = FloatArray(9)
        private val orientation = FloatArray(3)
        private var accuracy = SensorManager.SENSOR_STATUS_ACCURACY_HIGH

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            val sensor = manager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
            if (sensor == null) {
                events.error("no_sensor", "Kompas tidak tersedia", null)
                return
            }
            sink = events
            manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
        }

        override fun onCancel(arguments: Any?) {
            manager.unregisterListener(this)
            sink = null
        }

        override fun onSensorChanged(event: SensorEvent) {
            SensorManager.getRotationMatrixFromVector(rotation, event.values)
            SensorManager.getOrientation(rotation, orientation)
            val deg = (Math.toDegrees(orientation[0].toDouble()) + 360) % 360
            sink?.success(mapOf("heading" to deg, "accuracy" to accuracy))
        }

        override fun onAccuracyChanged(sensor: Sensor, value: Int) {
            accuracy = value
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
