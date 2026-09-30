package com.rinduramadan.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Bundle
import android.util.TypedValue
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.min

/**
 * Widget layar utama: kartu jadwal sholat yang sama dengan di dalam aplikasi
 * (`PrayerTimesCard`), disusun ulang dengan View native karena widget rumah
 * Android tidak bisa menjalankan Flutter.
 *
 * Bagian-bagiannya:
 * - Latar langit: frame PNG hasil render Flutter (per fase hari, beberapa
 *   pose animasi) disusun [SkyRenderer.sky] lalu disilangkan `ViewFlipper`
 *   - awan bergerak, bintang berkelip, tanpa proses apa pun berjalan.
 * - Busur matahari: [SkyRenderer.sunArc], posisi matahari dihitung dari
 *   jadwal terbit/terbenam saat widget di-refresh.
 * - Jam: `TextClock` (zona waktu lokasi) - berdetik sendiri tiap detik.
 * - Hitung mundur: `Chronometer` mode hitung-mundur - jalan sendiri.
 * - Enam sel sholat + sorotan "berikutnya"/"sedang berlangsung".
 *
 * Datanya (jadwal 7 hari + lokasi) ditulis Flutter lewat
 * `home_widget_service_io.dart`. Refresh dijadwalkan sendiri lewat
 * AlarmManager: di tiap waktu sholat (fase & sorotan berganti), tiap ~10
 * menit di siang hari (matahari bergeser), dan tengah malam (tanggal).
 */
private const val ATLAS_FRAMES = 6
private const val FRAME_STEP_MS = 1400.0
private const val ATLAS_CLOCK_BASE_MS = 20000.0

private const val CARD_RADIUS_DP = 24f

/** Margin lapisan busur (arc_layer di prayer_widget_layout.xml), dp. */
private const val ARC_MARGIN_TOP_DP = 30
private const val ARC_MARGIN_BOTTOM_DP = 46
private const val ARC_MARGIN_SIDE_DP = 6

private const val DAY_REFRESH_MS = 10L * 60 * 1000
private const val NIGHT_REFRESH_MS = 30L * 60 * 1000

class PrayerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        val data = WidgetData.parse(widgetData.getString("schedule_json", null))
        val state = data?.let { WidgetState(it, now) }

        appWidgetIds.forEach { id ->
            val options = appWidgetManager.getAppWidgetOptions(id)
            appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, state, options))
        }

        scheduleNextRefresh(context, state)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        // ukuran widget berubah (diregangkan pengguna): gambar ulang sesuai ukuran baru
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(refreshIntent(context))
    }

    /* ------------------------------------------------------------------ */

    companion object {
        /** Untuk WidgetPreviewActivity (debug): RemoteViews yang sama persis, pada jam [now]. */
        fun buildPreview(context: Context, prefs: SharedPreferences, options: Bundle, now: Long): RemoteViews {
            val data = WidgetData.parse(prefs.getString("schedule_json", null))
            return buildViews(context, prefs, data?.let { WidgetState(it, now) }, options)
        }

        private fun buildViews(
            context: Context,
            prefs: SharedPreferences,
            state: WidgetState?,
            options: Bundle,
        ): RemoteViews {
            val density = context.resources.displayMetrics.density
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 320
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 150
            val arcWidthDp = (widthDp - 2 * ARC_MARGIN_SIDE_DP).coerceAtLeast(60)
            val arcHeightDp = (heightDp - ARC_MARGIN_TOP_DP - ARC_MARGIN_BOTTOM_DP).coerceAtLeast(30)

            val phase = state?.phase ?: DayPhase.MORNING
            val night = phase.night
            val quiet = state?.quiet ?: false
            val variant = if (phase == DayPhase.NIGHT && quiet) "nightquiet" else phase.atlasName
            val season = state?.season?.takeIf { it != "normal" }

            // -------- anggaran memori bitmap RemoteViews (~6 byte/piksel layar) --------
            val dm = context.resources.displayMetrics
            val budget = 6L * dm.widthPixels * dm.heightPixels * 35 / 100
            var scale = density
            var frames = ATLAS_FRAMES
            fun bytesPerFrame(s: Float): Long {
                val sw = (widthDp * s).toLong(); val sh = (heightDp * s).toLong()
                val aw = (arcWidthDp * s).toLong(); val ah = (arcHeightDp * s).toLong()
                return 4L * (sw * sh + aw * ah)
            }
            // tiap child flipper di-parcel terpisah walau bitmapnya sama:
            // urutan bolak-balik = 2*frames-2 child, plus 1 gambar dasar
            fun totalBytes(n: Int, s: Float) = (2L * n - 2 + 1) * bytesPerFrame(s)
            while (totalBytes(frames, scale) > budget && scale > 1f) scale = (scale * 0.85f).coerceAtLeast(1f)
            while (totalBytes(frames, scale) > budget && frames > 2) frames--

            val skyW = (widthDp * scale).toInt().coerceAtLeast(1)
            val skyH = (heightDp * scale).toInt().coerceAtLeast(1)
            val arcW = (arcWidthDp * scale).toInt().coerceAtLeast(1)
            val arcH = (arcHeightDp * scale).toInt().coerceAtLeast(1)
            val showSun = state?.isDaytime == true

            // -------- ornamen Ramadan / Idulfitri --------
            val ornaments = if (season == null) emptyList() else ornamentRects(
                context, season, night, state.fireworks, state.data.location, widthDp, heightDp, scale,
            )

            val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            // -------- frame langit & busur --------
            // Urutan bolak-balik (0,1,..,5,4,..,1): frame yang bersebelahan selalu
            // mirip, termasuk saat flipper berputar kembali ke awal - tidak ada
            // lompatan. Frame 0 juga dipasang sebagai gambar dasar statis di bawah
            // flipper supaya celah saat fade tidak memperlihatkan wallpaper.
            val order = (0 until frames) + (frames - 2 downTo 1)
            val skyFrames = (0 until frames).map { f ->
                SkyRenderer.sky(
                    prefs, variant, f, phase, skyW, skyH, CARD_RADIUS_DP * scale, 1f * scale,
                    overlays = ornaments.map { (key, rect) -> "${key}_$f" to rect },
                )
            }
            val arcFrames = (0 until frames).map { f ->
                if (showSun) SkyRenderer.sunArc(arcW, arcH, state!!.sunProgress, ATLAS_CLOCK_BASE_MS + f * FRAME_STEP_MS, scale)
                else SkyRenderer.blank(arcW, arcH)
            }
            views.setImageViewBitmap(R.id.sky_base, skyFrames[0])
            views.setImageViewBitmap(R.id.arc_base, arcFrames[0])
            views.removeAllViews(R.id.sky_flipper)
            views.removeAllViews(R.id.arc_flipper)
            for (f in order) {
                val sky = RemoteViews(context.packageName, R.layout.prayer_widget_frame)
                sky.setImageViewBitmap(R.id.frame_image, skyFrames[f])
                views.addView(R.id.sky_flipper, sky)

                val arc = RemoteViews(context.packageName, R.layout.prayer_widget_frame)
                arc.setImageViewBitmap(R.id.frame_image, arcFrames[f])
                views.addView(R.id.arc_flipper, arc)
            }

            // -------- warna & latar per fase (padanan `night ? ... : ...` di Flutter) --------
            val muted = if (night) 0x99C7D2FE.toInt() else 0xFF78716C.toInt()
            val soft = if (night) 0xB3C7D2FE.toInt() else 0xFF78716C.toInt()
            val strong = if (night) 0xFFFFFFFF.toInt() else 0xFF1C1917.toInt()
            val pillFg = if (night) 0xFFEEF2FF.toInt() else 0xFF44403C.toInt()

            views.setTextColor(R.id.widget_title, phase.accent)
            views.setInt(R.id.widget_location_pill, "setBackgroundResource", if (night) R.drawable.widget_pill_night else R.drawable.widget_pill_day)
            views.setInt(R.id.widget_location_icon, "setColorFilter", pillFg)
            views.setTextColor(R.id.widget_location, pillFg)
            views.setTextColor(R.id.widget_clock, strong)
            views.setTextColor(R.id.widget_clock_seconds, phase.accent)
            views.setTextColor(R.id.widget_tz, if (night) 0xCCC7D2FE.toInt() else 0xFF78716C.toInt())
            views.setTextColor(R.id.widget_date, muted)
            views.setTextColor(R.id.widget_hijri, phase.accent)
            views.setTextColor(R.id.widget_next_label, soft)
            views.setTextColor(R.id.widget_countdown, if (night) 0xFFFFFFFF.toInt() else 0xFF292524.toInt())

            // -------- isi --------
            if (state == null) {
                views.setTextViewText(R.id.widget_location, context.getString(R.string.widget_default_location))
                views.setString(R.id.widget_clock, "setTimeZone", null)
                views.setString(R.id.widget_clock_seconds, "setTimeZone", null)
                views.setTextViewText(R.id.widget_tz, "")
                views.setTextViewText(R.id.widget_date, "Buka aplikasi untuk menyinkronkan")
                views.setTextViewText(R.id.widget_hijri, "")
                views.setTextViewText(R.id.widget_next_label, context.getString(R.string.widget_default_label))
                views.setChronometer(R.id.widget_countdown, SystemClock.elapsedRealtime(), "--:--", false)
                for (k in PRAYER_KEYS) {
                    views.setTextViewText(cellLabelId(k), PRAYER_LABELS[k]!!.uppercase())
                    views.setTextViewText(cellTimeId(k), "--:--")
                    styleCell(views, k, isNext = false, isActive = false, night = night)
                }
                return views
            }

            views.setTextViewText(R.id.widget_location, state.data.location)
            views.setString(R.id.widget_clock, "setTimeZone", state.data.tzId)
            views.setString(R.id.widget_clock_seconds, "setTimeZone", state.data.tzId)
            views.setTextViewText(R.id.widget_tz, state.data.tz)
            views.setTextViewText(R.id.widget_date, state.dateLabel)
            views.setTextViewText(R.id.widget_hijri, if (state.hijriLabel.isEmpty()) "" else "(${state.hijriLabel})")

            views.setTextViewText(R.id.widget_next_label, "MENUJU ${PRAYER_LABELS[state.next.key]!!.uppercase()}")
            // Chronometer memakai jam elapsedRealtime, bukan jam dinding
            val base = SystemClock.elapsedRealtime() + (state.next.at - state.now)
            views.setChronometerCountDown(R.id.widget_countdown, true)
            views.setChronometer(R.id.widget_countdown, base, null, true)

            for (k in PRAYER_KEYS) {
                views.setTextViewText(cellLabelId(k), PRAYER_LABELS[k]!!.uppercase())
                views.setTextViewText(cellTimeId(k), state.today.labels[k] ?: "--:--")
                styleCell(
                    views, k,
                    isNext = k == state.next.key && !state.next.isTomorrow,
                    isActive = k == state.current,
                    night = night,
                )
            }
            return views
        }

        /** Padanan `_PrayerCell` di Flutter. */
        private fun styleCell(views: RemoteViews, key: String, isNext: Boolean, isActive: Boolean, night: Boolean) {
            val bg = when {
                isNext -> R.drawable.widget_cell_next
                night -> if (isActive) R.drawable.widget_cell_night_active else R.drawable.widget_cell_night
                else -> if (isActive) R.drawable.widget_cell_day_active else R.drawable.widget_cell_day
            }
            val labelColor = when {
                isNext -> 0xD9FFFFFF.toInt()
                night -> 0xB3C7D2FE.toInt()
                else -> 0xFF78716C.toInt()
            }
            val timeColor = if (isNext || night) 0xFFFFFFFF.toInt() else 0xFF292524.toInt()
            views.setInt(cellId(key), "setBackgroundResource", bg)
            views.setTextColor(cellLabelId(key), labelColor)
            views.setTextColor(cellTimeId(key), timeColor)
        }

        private fun cellId(key: String) = when (key) {
            "fajr" -> R.id.cell_fajr
            "sunrise" -> R.id.cell_sunrise
            "dhuhr" -> R.id.cell_dhuhr
            "asr" -> R.id.cell_asr
            "maghrib" -> R.id.cell_maghrib
            else -> R.id.cell_isha
        }

        private fun cellLabelId(key: String) = when (key) {
            "fajr" -> R.id.cell_fajr_label
            "sunrise" -> R.id.cell_sunrise_label
            "dhuhr" -> R.id.cell_dhuhr_label
            "asr" -> R.id.cell_asr_label
            "maghrib" -> R.id.cell_maghrib_label
            else -> R.id.cell_isha_label
        }

        private fun cellTimeId(key: String) = when (key) {
            "fajr" -> R.id.cell_fajr_time
            "sunrise" -> R.id.cell_sunrise_time
            "dhuhr" -> R.id.cell_dhuhr_time
            "asr" -> R.id.cell_asr_time
            "maghrib" -> R.id.cell_maghrib_time
            else -> R.id.cell_isha_time
        }

        /**
         * Tempat lapisan ornamen (kanvas kecil hasil render Flutter, kunci
         * `orn_<musim>_<day|night>_<lapisan>`) dalam piksel bitmap langit:
         * - lampion/ketupat di celah antara judul & pil lokasi - lebar keduanya
         *   diukur (nama lokasi panjang = pil lebar), dikecilkan bila celahnya
         *   sempit, dilewati bila terlalu sempit;
         * - kembang api (malam Idulfitri & takbiran Iduladha) di celah antara tanggal hijriah &
         *   deretan waktu sholat, hanya bila celahnya cukup tinggi.
         * Angka dp mengikuti prayer_widget_layout.xml.
         */
        private fun ornamentRects(
            context: Context,
            season: String,
            night: Boolean,
            fireworks: Boolean,
            location: String,
            widthDp: Int,
            heightDp: Int,
            scale: Float,
        ): List<Pair<String, RectF>> {
            val light = if (night) "night" else "day"
            val out = mutableListOf<Pair<String, RectF>>()

            val titleEnd = 14f + textWidthDp(context, context.getString(R.string.widget_title), 9f, 0.18f) + 8f
            val pill = 9f + 11f + 4f + min(120f, textWidthDp(context, location, 10f, 0f)) + 9f
            val pillStart = widthDp - 14f - pill - 6f
            val band = pillStart - titleEnd
            if (band >= 44f) {
                val w = min(band, 120f)
                val h = w * 72f / 120f
                val left = titleEnd + (band - w) / 2f
                out += "orn_${season}_${light}_hangers" to RectF(left * scale, 0f, (left + w) * scale, h * scale)
            }

            if (night && fireworks) {
                val top = 96f
                val gap = heightDp - 44f - top
                if (gap >= 30f) {
                    val h = min(gap, 56f)
                    val w = min(h * 200f / 56f, widthDp * 0.6f)
                    val y = top + (gap - h) / 2f
                    out += "orn_${season}_night_fireworks" to RectF(16f * scale, y * scale, (16f + w) * scale, (y + h) * scale)
                }
            }
            return out
        }

        /** Lebar teks tebal [sp] dengan jarak huruf [spacing] em, dalam dp. */
        private fun textWidthDp(context: Context, text: String, sp: Float, spacing: Float): Float {
            val metrics = context.resources.displayMetrics
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sp, metrics)
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = spacing
            }
            return paint.measureText(text) / metrics.density
        }
    }

    /* ------------------------------------------------------------------ */

    private fun refreshIntent(context: Context): PendingIntent {
        val ids = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
        val intent = Intent(context, PrayerWidgetProvider::class.java)
            .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        return PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Refresh berikutnya: waktu sholat berikutnya (+1 dtk), tengah malam,
     * atau jeda rutin - 10 mnt siang (matahari bergeser), 30 mnt malam.
     * Alarm tak-eksak: cukup, tidak butuh izin khusus, hemat baterai.
     */
    private fun scheduleNextRefresh(context: Context, state: WidgetState?) {
        val now = System.currentTimeMillis()
        val periodic = now + if (state?.isDaytime == true) DAY_REFRESH_MS else NIGHT_REFRESH_MS
        var at = periodic
        if (state != null) {
            at = min(at, state.next.at + 1000)
            at = min(at, state.nextMidnight + 1000)
        }
        at = at.coerceAtLeast(now + 60_000)

        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.setAndAllowWhileIdle(AlarmManager.RTC, at, refreshIntent(context))
    }
}
