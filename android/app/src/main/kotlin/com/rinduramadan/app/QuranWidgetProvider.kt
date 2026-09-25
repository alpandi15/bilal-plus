package com.rinduramadan.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/**
 * Widget Al-Qur'an: cincin progress khatam (berbobot halaman), posisi
 * terakhir, target hari ini, grafik halaman 7 hari (bila cukup tinggi), dan
 * tombol "Lanjut baca" yang membuka halaman Tilawah di aplikasi.
 *
 * Datanya (`quran_json`) disusun Flutter (`tracker_widget_payload.dart`);
 * target untuk hari ini & besok sudah dihitung di sana.
 */
class QuranWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        appWidgetIds.forEach { id ->
            val options = appWidgetManager.getAppWidgetOptions(id)
            appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, options, now))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
    }

    companion object {
        /** Tinggi minimal agar grafik 7 hari ditampilkan (2x4). */
        private const val CHART_MIN_HEIGHT_DP = 260

        fun buildViews(context: Context, prefs: SharedPreferences, options: Bundle, now: Long): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.quran_widget_layout)
            val open = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rinduramadan://quran"),
            )
            views.setOnClickPendingIntent(R.id.qw_root, open)
            views.setOnClickPendingIntent(R.id.qw_continue, open)

            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 150
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 220

            val root = prefs.getString("quran_json", null)?.let {
                try { JSONObject(it) } catch (_: Exception) { null }
            }
            if (root == null) {
                views.setTextViewText(R.id.qw_kicker, "TILAWAH AL-QUR'AN")
                views.setProgressBar(R.id.qw_ring, 1000, 0, false)
                views.setTextViewText(R.id.qw_percent, "—")
                views.setTextViewText(R.id.qw_juz, "Belum ada data")
                views.setTextViewText(R.id.qw_position, "Buka aplikasi untuk memulai")
                views.setViewVisibility(R.id.qw_target_box, View.GONE)
                views.setTextViewText(R.id.qw_continue, "Buka aplikasi ›")
                return views
            }

            val round = root.optInt("round", 1)
            val justKhatam = root.optBoolean("justKhatam", false)
            val last = root.optInt("lastAyah", 0)
            views.setTextViewText(
                R.id.qw_kicker,
                if (justKhatam) "ALHAMDULILLAH, KHATAM KE-$round" else "KHATAM KE-$round",
            )
            val progress = root.optDouble("progress", 0.0)
            views.setProgressBar(R.id.qw_ring, 1000, (progress * 1000).toInt(), false)
            views.setTextViewText(R.id.qw_percent, "${root.optInt("percent", 0)}%")
            if (last == 0) {
                views.setTextViewText(R.id.qw_juz, if (justKhatam) "Putaran baru" else "Belum mulai")
                views.setTextViewText(R.id.qw_position, "Mulai dari Al-Fatihah")
                views.setTextViewText(R.id.qw_continue, "Mulai baca ›")
            } else {
                views.setTextViewText(R.id.qw_juz, "Juz ${root.optInt("juz")}")
                views.setTextViewText(
                    R.id.qw_position,
                    "${root.optString("position")} · hlm ${root.optInt("page")}",
                )
                views.setTextViewText(R.id.qw_continue, "Lanjut baca ›")
            }

            // target hari ini (datanya memuat hari ini & besok)
            val cal = Calendar.getInstance(TimeZone.getTimeZone(root.optString("tzId", "Asia/Jakarta")))
                .apply { timeInMillis = now }
            val today = "%04d-%02d-%02d".format(
                cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
            )
            val days = root.optJSONArray("days")
            val day = days?.let { arr ->
                (0 until arr.length()).map { arr.getJSONObject(it) }.firstOrNull { it.getString("date") == today }
            }
            when {
                day == null || heightDp < 200 -> views.setViewVisibility(R.id.qw_target_box, View.GONE)
                !day.optBoolean("hasTarget", false) -> {
                    views.setTextViewText(R.id.qw_target, "Atur target khatam di aplikasi")
                    views.setViewVisibility(R.id.qw_pages, View.GONE)
                    views.setViewVisibility(R.id.qw_target_bar, View.GONE)
                }
                else -> {
                    val reached = day.optBoolean("reached", false)
                    views.setTextViewText(
                        R.id.qw_target,
                        if (reached) "Target hari ini tercapai" else "Target: ${day.optString("target")}",
                    )
                    views.setTextViewText(R.id.qw_pages, day.optString("pagesLabel"))
                    val perDay = day.optDouble("pagesPerDay", 0.0)
                    val done = day.optDouble("pagesToday", 0.0)
                    val fraction = if (perDay <= 0) 1.0 else (done / perDay).coerceIn(0.0, 1.0)
                    views.setProgressBar(R.id.qw_target_bar, 1000, (fraction * 1000).toInt(), false)
                }
            }
            views.setViewVisibility(R.id.qw_position, if (heightDp < 170) View.GONE else View.VISIBLE)

            // grafik 7 hari - hanya bila widget diregangkan cukup tinggi
            if (heightDp >= CHART_MIN_HEIGHT_DP) {
                val week = root.optJSONArray("week")
                val labels = root.optJSONArray("weekLabels")
                if (week != null && labels != null && week.length() == 7) {
                    val chartHeightDp = (heightDp - 225).coerceIn(44, 110)
                    val bitmap = weekChart(
                        context,
                        values = (0 until 7).map { week.getDouble(it) },
                        labels = (0 until 7).map { labels.getString(it) },
                        widthDp = (widthDp - 24).coerceAtLeast(80),
                        heightDp = chartHeightDp,
                    )
                    views.setImageViewBitmap(R.id.qw_chart, bitmap)
                    views.setViewVisibility(R.id.qw_chart, View.VISIBLE)
                    views.setViewVisibility(R.id.qw_spacer, View.GONE)
                }
            }
            return views
        }

        /** Batang halaman per hari; hari ini (paling kanan) paling terang. */
        private fun weekChart(
            context: Context,
            values: List<Double>,
            labels: List<String>,
            widthDp: Int,
            heightDp: Int,
        ): Bitmap {
            val d = context.resources.displayMetrics.density
            val w = (widthDp * d).toInt().coerceAtLeast(1)
            val h = (heightDp * d).toInt().coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFB9D3CB.toInt()
                textSize = 8f * d
                textAlign = Paint.Align.CENTER
            }
            val valuePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = 0xFFF7F1E1.toInt()
                textSize = 7.5f * d
                textAlign = Paint.Align.CENTER
                typeface = Typeface.DEFAULT_BOLD
            }
            val labelH = 12f * d
            val valueH = 10f * d
            val barAreaTop = valueH
            val barAreaBottom = h - labelH
            val slot = w / 7f
            val barW = (slot * 0.5f).coerceAtMost(16f * d)
            val max = (values.maxOrNull() ?: 0.0).coerceAtLeast(1.0)
            val track = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x1FE3BE6A }

            values.forEachIndexed { i, v ->
                val cx = slot * i + slot / 2
                val left = cx - barW / 2
                val right = cx + barW / 2
                val radius = barW / 2
                canvas.drawRoundRect(RectF(left, barAreaTop, right, barAreaBottom), radius, radius, track)
                if (v > 0) {
                    val top = barAreaBottom - ((barAreaBottom - barAreaTop) * (v / max)).toFloat()
                        .coerceAtLeast(barW)
                    val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        shader = LinearGradient(
                            0f, top, 0f, barAreaBottom,
                            if (i == 6) 0xFFF2D38A.toInt() else 0xCCE3BE6A.toInt(),
                            if (i == 6) 0xFFD9A441.toInt() else 0x99D9A441.toInt(),
                            Shader.TileMode.CLAMP,
                        )
                    }
                    canvas.drawRoundRect(RectF(left, top, right, barAreaBottom), radius, radius, fill)
                    val label = if (v >= 10 || v == Math.floor(v)) v.toInt().toString() else "%.1f".format(v)
                    canvas.drawText(label, cx, top - 2f * d, valuePaint)
                }
                labelPaint.isFakeBoldText = i == 6
                labelPaint.color = if (i == 6) 0xFFE3BE6A.toInt() else 0xFFB9D3CB.toInt()
                canvas.drawText(labels[i], cx, h - 2f * d, labelPaint)
            }
            return bitmap
        }
    }
}
