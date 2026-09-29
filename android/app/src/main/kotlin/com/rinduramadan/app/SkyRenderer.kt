package com.rinduramadan.app

import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import java.io.File
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * Penggambar latar kartu widget. Dua bagian:
 *
 * 1. [sky] - menyusun satu frame latar: gradasi fase hari sebagai cadangan,
 *    lalu PNG langit hasil render Flutter (`sky_<fase>_<frame>`) ditarik
 *    memenuhi kartu, dipotong sudut membulat, diberi garis tepi. Frame-frame
 *    ini nanti disilangkan ViewFlipper jadi animasi awan/bintang.
 * 2. [sunArc] - busur & matahari, port langsung `SunPositionArc` Flutter
 *    (_ArcPainter + _SunBody): pita oval meruncing, halo berdenyut, sinar
 *    berputar, inti bergradasi. Malam hari busurnya disembunyikan, sama
 *    seperti `hideAtNight: true` di kartu aplikasi.
 */
object SkyRenderer {

    fun sky(
        prefs: SharedPreferences,
        variant: String,
        frame: Int,
        phase: DayPhase,
        width: Int,
        height: Int,
        radiusPx: Float,
        borderPx: Float,
        overlays: List<Pair<String, RectF>> = emptyList(),
    ): Bitmap {
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val bounds = RectF(0f, 0f, width.toFloat(), height.toFloat())
        val clip = Path().apply { addRoundRect(bounds, radiusPx, radiusPx, Path.Direction.CW) }
        canvas.clipPath(clip)

        // gradasi fase (topLeft -> bottomRight) - tampil kalau atlas belum ada
        canvas.drawRect(
            bounds,
            Paint().apply {
                shader = LinearGradient(0f, 0f, width.toFloat(), height.toFloat(), phase.bg, null, Shader.TileMode.CLAMP)
            },
        )

        val path = prefs.getString("sky_${variant}_$frame", null)
        val src = path?.let { decodeScaled(it, width, height) }
        if (src != null) {
            canvas.drawBitmap(src, null, bounds, Paint(Paint.FILTER_BITMAP_FLAG))
            src.recycle()
        } else {
            // cadangan tanpa atlas: scrim tipis saja supaya teks tetap terbaca
            val scrim = if (phase.night) intArrayOf(0xC716233D.toInt(), 0x1A16233D, 0x3816233D)
            else intArrayOf(0xB3FFFFFF.toInt(), 0x0AFFFFFF, 0x38FFFFFF)
            canvas.drawRect(
                bounds,
                Paint().apply { shader = LinearGradient(0f, 0f, 0f, height.toFloat(), scrim, null, Shader.TileMode.CLAMP) },
            )
        }

        // ornamen musiman (lampion/ketupat/kembang api, PNG transparan) di
        // atas langit & scrim - sama dengan urutan lapisan di kartu aplikasi
        // Kanvasnya kecil & sudah ditempatkan pemanggil di celah teks.
        for ((key, rect) in overlays) {
            val path = prefs.getString(key, null) ?: continue
            val bmp = decodeScaled(path, rect.width().toInt().coerceAtLeast(1), rect.height().toInt().coerceAtLeast(1))
                ?: continue
            canvas.drawBitmap(bmp, null, rect, Paint(Paint.FILTER_BITMAP_FLAG))
            bmp.recycle()
        }
        // garis tepi 1dp - di atas langit, seperti foregroundDecoration di Flutter
        val inset = borderPx / 2
        canvas.drawRoundRect(
            RectF(inset, inset, width - inset, height - inset),
            radiusPx - inset, radiusPx - inset,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = borderPx
                color = if (phase.night) 0x1AFFFFFF else 0xB3FFFFFF.toInt()
            },
        )
        return bmp
    }

    private fun decodeScaled(path: String, targetW: Int, targetH: Int): Bitmap? {
        val file = File(path)
        if (!file.exists()) return null
        val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, opts)
        if (opts.outWidth <= 0) return null
        var sample = 1
        while (opts.outWidth / (sample * 2) >= targetW && opts.outHeight / (sample * 2) >= targetH) sample *= 2
        return BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
    }

    /* ------------------------- busur matahari ------------------------- */

    // geometri dalam satuan persen, persis konstanta SunPositionArc
    private const val X_MIN = 4.0
    private const val X_MAX = 96.0
    private const val CX = (X_MIN + X_MAX) / 2
    private const val RX = (X_MAX - X_MIN) / 2
    private const val HORIZON = 84.0
    private const val RY = 60.0
    private const val TAPER_HALF = 1.9

    private class ArcPoint(val x: Double, val y: Double, val elevation: Double)

    private fun pointAt(progress: Double): ArcPoint {
        val t = PI * (1 - progress)
        return ArcPoint(CX + RX * cos(t), HORIZON - RY * sin(t), sin(t))
    }

    private fun lerpColor(a: Int, b: Int, t: Float): Int {
        val u = t.coerceIn(0f, 1f)
        fun ch(shift: Int) = ((a shr shift and 0xFF) + ((b shr shift and 0xFF) - (a shr shift and 0xFF)) * u).toInt()
        return (ch(24) shl 24) or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
    }

    private fun withAlpha(color: Int, alpha: Float): Int =
        (color and 0x00FFFFFF) or ((alpha.coerceIn(0f, 1f) * 255).toInt() shl 24)

    /** Warna matahari mengikuti ketinggian - padanan `_sunColor`. */
    private fun sunColor(elevation: Double): Int {
        val low = 0xFFFF5A00.toInt(); val mid = 0xFFFF9A1F.toInt(); val high = 0xFFFFCE3A.toInt()
        return if (elevation < 0.5) lerpColor(low, mid, (elevation / 0.5).toFloat())
        else lerpColor(mid, high, ((elevation - 0.5) / 0.5).toFloat())
    }

    /** Gelombang segitiga 0..1 -> from..to..from - padanan `triangleWave`. */
    private fun triangleWave(phase: Double, from: Float, to: Float): Float {
        val p = if (phase < 0.5) phase * 2 else (1 - phase) * 2
        return from + (to - from) * p.toFloat()
    }

    fun sunArc(width: Int, height: Int, progress: Double, clockMs: Double, density: Float): Bitmap {
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val sx = width / 100f
        val sy = height / 100f
        val steps = 96

        // haze isi oval
        canvas.save()
        canvas.scale(sx, sy)
        val fill = Path()
        val p0 = pointAt(0.0)
        fill.moveTo(p0.x.toFloat(), p0.y.toFloat())
        for (i in 1..steps) {
            val p = pointAt(i.toDouble() / steps)
            fill.lineTo(p.x.toFloat(), p.y.toFloat())
        }
        fill.close()
        canvas.drawPath(
            fill,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(0f, 0f, 0f, 100f, 0x73FFECB4, 0x00FFFFFF, Shader.TileMode.CLAMP)
            },
        )

        // pita meruncing
        val top = ArrayList<FloatArray>(steps + 1)
        val bottom = ArrayList<FloatArray>(steps + 1)
        for (i in 0..steps) {
            val t = i.toDouble() / steps
            val p = pointAt(t)
            val half = TAPER_HALF * sin(PI * t)
            top.add(floatArrayOf(p.x.toFloat(), (p.y - half).toFloat()))
            bottom.add(floatArrayOf(p.x.toFloat(), (p.y + half).toFloat()))
        }
        val ribbon = Path().apply {
            moveTo(top[0][0], top[0][1])
            for (i in 1..steps) lineTo(top[i][0], top[i][1])
            for (i in steps downTo 0) lineTo(bottom[i][0], bottom[i][1])
            close()
        }
        canvas.drawPath(ribbon, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x57D97706 })
        canvas.restore()

        // matahari
        val point = pointAt(progress)
        val rgb = sunColor(point.elevation)
        val cx = (point.x / 100 * width).toFloat()
        val cy = (point.y / 100 * height).toFloat()
        val body = 22f * density

        val haloPhase = (clockMs % 3400) / 3400
        val haloScale = triangleWave(haloPhase, 0.92f, 1.12f)
        val haloOpacity = triangleWave(haloPhase, 0.75f, 1f)
        val rayRotation = ((clockMs % 44000) / 44000 * 360).toFloat()

        // halo berdenyut
        val haloR = body * 1.5f * haloScale
        canvas.drawCircle(
            cx, cy, haloR,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(
                    cx, cy, haloR,
                    intArrayOf(withAlpha(rgb, 0.52f * haloOpacity), withAlpha(rgb, 0f)),
                    floatArrayOf(0f, 0.68f), Shader.TileMode.CLAMP,
                )
            },
        )

        // sinar: irisan tiap 27 derajat selebar 5 derajat, dipotong jadi cincin
        val rayR = body * 2.1f / 2
        val rayRect = RectF(cx - rayR, cy - rayR, cx + rayR, cy + rayR)
        val layer = canvas.saveLayer(rayRect, null)
        canvas.save()
        canvas.rotate(rayRotation, cx, cy)
        val wedge = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = withAlpha(rgb, 0.45f) }
        var a = 0f
        while (a < 360f) {
            canvas.drawArc(rayRect, a, 5f, true, wedge)
            a += 27f
        }
        canvas.restore()
        canvas.drawRect(
            rayRect,
            Paint().apply {
                shader = RadialGradient(
                    cx, cy, rayR,
                    intArrayOf(0, 0, Color.BLACK, Color.BLACK, 0, 0),
                    floatArrayOf(0f, 0.34f, 0.44f, 0.72f, 0.82f, 1f), Shader.TileMode.CLAMP,
                )
                xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
            },
        )
        canvas.restoreToCount(layer)

        // cahaya sekeliling inti (padanan boxShadow blur = bodySize)
        canvas.drawCircle(
            cx, cy, body,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(
                    cx, cy, body,
                    intArrayOf(withAlpha(rgb, 0.85f), withAlpha(rgb, 0f)),
                    floatArrayOf(0.4f, 1f), Shader.TileMode.CLAMP,
                )
            },
        )

        // inti: sorot putih agak ke kiri-atas
        val r = body / 2
        canvas.drawCircle(
            cx, cy, r,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(
                    cx - 0.3f * r, cy - 0.36f * r, r * 1.3f,
                    intArrayOf(0xF2FFFFFF.toInt(), rgb),
                    floatArrayOf(0f, 0.62f), Shader.TileMode.CLAMP,
                )
            },
        )
        return bmp
    }

    /** Frame kosong (malam: busur disembunyikan). */
    fun blank(width: Int, height: Int): Bitmap =
        Bitmap.createBitmap(width.coerceAtLeast(1), height.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
}
