package com.rinduramadan.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.Layout
import android.text.SpannableString
import android.text.Spanned
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.text.TextUtils
import android.text.style.ForegroundColorSpan
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import kotlin.math.max
import kotlin.math.min

/**
 * Widget Hafalan: ayat berikutnya yang belum hafal dari surah yang sedang
 * dihafal (mis. Al-Insyiqaq 1-3 sudah hafal -> tampil ayat 4), digambar
 * besar dengan font mushaf pilihan pengguna (LPMQ / Utsmani) supaya jelas &
 * mudah dihafal.
 *
 * - "Tutup" ([ACTION_PEEK]) menyembunyikan ayat kecuali kata pertama -
 *   kata lainnya jadi blok samar di posisinya, untuk menguji hafalan.
 * - Ketuk di mana pun selain tombol membuka halaman hafalan surahnya.
 * - "Hafal" ([ACTION_HAFAL]) langsung maju ke ayat berikutnya (tertunda,
 *   seperti centang widget Ibadah) lalu diteruskan ke Dart di latar
 *   (`trackerWidgetCallback`) yang menulis ke basis data & menyusun ulang
 *   `hafalan_json`.
 */
class HafalanWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val options = appWidgetManager.getAppWidgetOptions(id)
            appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, options))
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

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_HAFAL -> {
                val uri = intent.data ?: return
                val ayah = uri.getQueryParameter("ayah")?.toIntOrNull() ?: return
                setPending(context, ayah)
                refreshAll(context)
                // tulis ke basis data lewat Dart di latar
                HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
            }
            ACTION_PEEK -> {
                val prefs = statePrefs(context)
                prefs.edit().putBoolean(HIDDEN_KEY, !prefs.getBoolean(HIDDEN_KEY, false)).apply()
                refreshAll(context)
            }
            else -> super.onReceive(context, intent)
        }
    }

    companion object {
        const val ACTION_HAFAL = "com.rinduramadan.app.HAFALAN_SET"
        const val ACTION_PEEK = "com.rinduramadan.app.HAFALAN_PEEK"
        private const val STATE_PREFS = "hafalan_widget_state"
        private const val PENDING_KEY = "pending"
        private const val HIDDEN_KEY = "hidden"

        private const val CREAM = 0xFFF4F1EA.toInt()
        private const val GOLD = 0xFFF2D38A.toInt()

        private val typefaces = mutableMapOf<String, Typeface?>()

        private fun statePrefs(context: Context) =
            context.getSharedPreferences(STATE_PREFS, Context.MODE_PRIVATE)

        /* ---------------------------- tertunda ---------------------------- */

        private fun setPending(context: Context, ayah: Int) {
            val prefs = statePrefs(context)
            val all = JSONObject(prefs.getString(PENDING_KEY, "{}") ?: "{}")
            all.put(ayah.toString(), System.currentTimeMillis())
            prefs.edit().putString(PENDING_KEY, all.toString()).apply()
        }

        /** Ayat yang ditandai hafal dari widget tapi belum tercermin di data. */
        private fun pending(context: Context, generatedAt: Long): Set<Int> {
            val prefs = statePrefs(context)
            val all = JSONObject(prefs.getString(PENDING_KEY, "{}") ?: "{}")
            val live = JSONObject()
            all.keys().forEach { k -> if (all.getLong(k) > generatedAt) live.put(k, all.getLong(k)) }
            if (live.length() != all.length()) prefs.edit().putString(PENDING_KEY, live.toString()).apply()
            return live.keys().asSequence().mapNotNull { it.toIntOrNull() }.toSet()
        }

        private fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, HafalanWidgetProvider::class.java))
            val prefs = HomeWidgetPlugin.getData(context)
            ids.forEach { id -> manager.updateAppWidget(id, buildViews(context, prefs, manager.getAppWidgetOptions(id))) }
        }

        /* ----------------------------- intent ----------------------------- */

        private fun broadcast(context: Context, action: String, uri: Uri?, code: Int): PendingIntent {
            val intent = Intent(context, HafalanWidgetProvider::class.java).apply {
                this.action = action
                data = uri
            }
            return PendingIntent.getBroadcast(
                context, code, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun open(context: Context, surah: Int?): PendingIntent =
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rinduramadan://hafalan" + (surah?.let { "?surah=$it" } ?: "")),
            )

        /* ----------------------------- gambar ----------------------------- */

        fun buildViews(context: Context, prefs: SharedPreferences, options: Bundle): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.hafalan_widget_layout)
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 120

            val root = prefs.getString("hafalan_json", null)?.let {
                try { JSONObject(it) } catch (_: Exception) { null }
            }
            val surah = root?.optInt("surah", 0)?.takeIf { it > 0 }
            views.setOnClickPendingIntent(R.id.hw_root, open(context, surah))
            views.setOnClickPendingIntent(R.id.hw_header, open(context, surah))

            if (root == null || surah == null) {
                return empty(
                    views, context,
                    "HAFALAN AL-QUR'AN",
                    "Tandai ayat yang sudah hafal di mode hafalan - ayat berikutnya muncul di sini.",
                    "Mulai hafalan ›",
                )
            }

            val name = root.optString("name")
            val total = root.optInt("ayahCount", 0)
            val skip = pending(context, root.optLong("generatedAt", 0L))
            val queue = root.optJSONArray("queue")
            val next = (0 until (queue?.length() ?: 0))
                .map { queue!!.getJSONObject(it) }
                .firstOrNull { it.optInt("i") !in skip }
            val memorized = min(total, root.optInt("memorized", 0) + skip.size)

            views.setTextViewText(R.id.hw_kicker, "HAFALAN · ${name.uppercase()}")
            views.setTextViewText(R.id.hw_count, "$memorized/$total")
            views.setProgressBar(R.id.hw_progress, 1000, if (total == 0) 0 else memorized * 1000 / total, false)

            if (next == null) {
                // surah tuntas (atau antrean habis menunggu data baru)
                val done = memorized >= total
                return empty(
                    views, context,
                    "HAFALAN · ${name.uppercase()}",
                    if (done) "Masyaa Allah, $name sudah hafal semua! Pilih surah berikutnya di aplikasi."
                    else "Menyiapkan ayat berikutnya… ketuk untuk membuka aplikasi.",
                    if (done) "Pilih surah ›" else "Buka ›",
                    keepHeader = true,
                )
            }

            val number = next.optInt("n")
            val hidden = statePrefs(context).getBoolean(HIDDEN_KEY, false)
            val density = context.resources.displayMetrics.density

            // ruang (dp): padding 22, kepala 16, bar 11, panel ayat (margin 8 +
            // padding 12), kaki 36; terjemahan 2 baris ±32 bila masih lega
            val fixed = 22 + 16 + 11 + 20 + 36
            val showTranslation = heightDp - fixed - 32 >= 56
            val ayahH = heightDp - fixed - (if (showTranslation) 32 else 0)
            val ayahW = widthDp - 28 - 12

            val bitmap = renderAyah(
                context,
                next.optString("ar"),
                root.optString("font", "lpmq"),
                (ayahW * density).toInt().coerceAtLeast(60),
                (ayahH * density).toInt().coerceAtLeast(40),
                hidden,
            )
            views.setViewVisibility(R.id.hw_ayah, View.VISIBLE)
            views.setViewVisibility(R.id.hw_empty, View.GONE)
            views.setImageViewBitmap(R.id.hw_ayah, bitmap)
            views.setContentDescription(R.id.hw_ayah, "$name ayat $number")
            // ketuk ayat = buka halaman hafalan surahnya (area terbesar -
            // harus membuka aplikasi); tutup/lihat hanya lewat tombolnya
            views.setOnClickPendingIntent(R.id.hw_ayah_box, open(context, surah))

            views.setViewVisibility(R.id.hw_translation, if (showTranslation && !hidden) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.hw_translation, next.optString("tr"))

            views.setTextViewText(R.id.hw_label, if (widthDp >= 230) "Ayat $number dari $total" else "Ayat $number")
            views.setViewVisibility(R.id.hw_peek, View.VISIBLE)
            views.setTextViewText(R.id.hw_peek, if (hidden) "Lihat" else "Tutup")
            views.setOnClickPendingIntent(R.id.hw_peek, broadcast(context, ACTION_PEEK, null, 1))
            views.setViewVisibility(R.id.hw_done, View.VISIBLE)
            views.setTextViewText(R.id.hw_done, "✓ Hafal")
            views.setOnClickPendingIntent(
                R.id.hw_done,
                broadcast(context, ACTION_HAFAL, Uri.parse("rinduramadan://hafalan/set?ayah=${next.optInt("i")}"), 2),
            )
            return views
        }

        private fun empty(
            views: RemoteViews,
            context: Context,
            kicker: String,
            message: String,
            button: String,
            keepHeader: Boolean = false,
        ): RemoteViews {
            views.setTextViewText(R.id.hw_kicker, kicker)
            if (!keepHeader) {
                views.setTextViewText(R.id.hw_count, "—")
                views.setProgressBar(R.id.hw_progress, 1000, 0, false)
            }
            views.setViewVisibility(R.id.hw_ayah, View.GONE)
            views.setViewVisibility(R.id.hw_empty, View.VISIBLE)
            views.setTextViewText(R.id.hw_empty, message)
            views.setViewVisibility(R.id.hw_translation, View.GONE)
            views.setTextViewText(R.id.hw_label, "")
            views.setViewVisibility(R.id.hw_peek, View.GONE)
            views.setViewVisibility(R.id.hw_done, View.VISIBLE)
            views.setTextViewText(R.id.hw_done, button)
            val open = open(context, null)
            views.setOnClickPendingIntent(R.id.hw_done, open)
            views.setOnClickPendingIntent(R.id.hw_ayah_box, open)
            return views
        }

        private fun typeface(context: Context, font: String): Typeface? = typefaces.getOrPut(font) {
            val file = if (font == "uthmani") "UthmanicHafs_V18.ttf" else "LPMQ.ttf"
            try {
                Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/$file")
            } catch (_: Exception) {
                null
            }
        }

        /**
         * Ayat [text] rata tengah kanan-ke-kiri sebesar mungkin (34..13sp)
         * dalam [w]x[h] px. [hidden]: hanya kata pertama (emas), kata lain
         * jadi blok samar di posisinya.
         */
        internal fun renderAyah(
            context: Context,
            text: String,
            font: String,
            w: Int,
            h: Int,
            hidden: Boolean,
        ): Bitmap {
            val metrics = context.resources.displayMetrics
            val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = typeface(context, font)
                color = CREAM
            }
            val spannable = SpannableString(text)
            // kata pertama selalu emas (petunjuk); saat ditutup kata lain tak
            // terlihat & diganti blok
            val firstEnd = text.indexOf(' ').let { if (it < 0) text.length else it }
            spannable.setSpan(ForegroundColorSpan(GOLD), 0, firstEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            if (hidden && firstEnd < text.length) {
                spannable.setSpan(ForegroundColorSpan(0), firstEnd, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }

            var layout: StaticLayout? = null
            var sp = 34f
            while (sp >= 13f) {
                paint.textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sp, metrics)
                val l = build(spannable, paint, w, Int.MAX_VALUE)
                if (l.height <= h) {
                    layout = l
                    break
                }
                sp -= 1f
            }
            if (layout == null) {
                // ayat panjang: sebanyak yang muat, sisanya "…" (ketuk untuk
                // membaca lengkap di aplikasi)
                val lineH = build(SpannableString("ا"), paint, w, 1).height
                layout = build(spannable, paint, w, max(1, h / max(1, lineH)))
            }

            val bitmap = Bitmap.createBitmap(w, max(1, min(h, layout.height)), Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            if (hidden) {
                val block = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x2EF4F1EA }
                val r = paint.textSize * 0.22f
                var start = firstEnd
                while (start < text.length) {
                    while (start < text.length && text[start] == ' ') start++
                    if (start >= text.length) break
                    var end = text.indexOf(' ', start)
                    if (end < 0) end = text.length
                    val line = layout.getLineForOffset(start)
                    if (line < layout.lineCount && layout.getLineForOffset(max(start, end - 1)) == line) {
                        val x1 = layout.getPrimaryHorizontal(start)
                        val x2 = layout.getPrimaryHorizontal(end).let {
                            // akhir baris: posisi tepi kiri baris (RTL)
                            if (end >= layout.getLineEnd(line) - 1) layout.getLineLeft(line) else it
                        }
                        val top = layout.getLineTop(line) + (layout.getLineBottom(line) - layout.getLineTop(line)) * 0.28f
                        val bottom = layout.getLineBottom(line) - (layout.getLineBottom(line) - layout.getLineTop(line)) * 0.22f
                        canvas.drawRoundRect(RectF(min(x1, x2) + 2, top, max(x1, x2) - 2, bottom), r, r, block)
                    }
                    start = end
                }
            }
            layout.draw(canvas)
            return bitmap
        }

        private fun build(text: CharSequence, paint: TextPaint, w: Int, maxLines: Int): StaticLayout =
            if (Build.VERSION.SDK_INT >= 23) {
                StaticLayout.Builder.obtain(text, 0, text.length, paint, w)
                    .setAlignment(Layout.Alignment.ALIGN_CENTER)
                    .setTextDirection(TextDirectionHeuristics.RTL)
                    .setLineSpacing(0f, 1.05f)
                    .setIncludePad(true)
                    .setMaxLines(maxLines)
                    .setEllipsize(if (maxLines == Int.MAX_VALUE) null else TextUtils.TruncateAt.END)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                StaticLayout(text, paint, w, Layout.Alignment.ALIGN_CENTER, 1.05f, 0f, true)
            }
    }
}
