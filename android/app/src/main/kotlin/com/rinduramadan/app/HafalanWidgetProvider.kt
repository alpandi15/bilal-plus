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
 * - Mode "petunjuk" (`mode` = cue di `hafalan_json`): beberapa ayat
 *   berikutnya sekaligus, hanya kata awal tiap ayat; "Intip" menampilkan
 *   ayat pertamanya utuh, "Hafal" menandai ayat pertama.
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
                val key = if (isCueMode(context)) CUE_PEEK_KEY else HIDDEN_KEY
                prefs.edit().putBoolean(key, !prefs.getBoolean(key, false)).apply()
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
        private const val CUE_PEEK_KEY = "cue_peek"
        private const val CUE_MIN_SP = 16f
        private const val CUE_LINE_SPACING = 0.78f

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

        /** Widget sedang dalam mode petunjuk (beberapa ayat, kata awal saja)? */
        private fun isCueMode(context: Context): Boolean = try {
            JSONObject(HomeWidgetPlugin.getData(context).getString("hafalan_json", null) ?: "{}")
                .optString("mode") == "cue"
        } catch (_: Exception) {
            false
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

            views.setTextViewText(R.id.hw_kicker, kicker(name, root.optInt("murajaah", 0)))
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
            val cueMode = root.optString("mode") == "cue"
            val cueItems = if (cueMode) {
                (0 until (queue?.length() ?: 0))
                    .map { queue!!.getJSONObject(it) }
                    .filter { it.optInt("i") !in skip }
                    .take(root.optInt("cueCount", 5).coerceIn(2, 8))
            } else {
                emptyList()
            }
            val peeking = cueMode && statePrefs(context).getBoolean(CUE_PEEK_KEY, false)
            val cueList = cueMode && !peeking
            // mode ayat penuh: "Tutup" menyamarkan; mode petunjuk: "Intip"
            val hidden = !cueMode && statePrefs(context).getBoolean(HIDDEN_KEY, false)
            val density = context.resources.displayMetrics.density

            // ruang (dp): padding 22, kepala 16, bar 11, panel ayat (margin 8 +
            // padding 12), kaki 36; terjemahan 2 baris ±32 bila masih lega
            val fixed = 22 + 16 + 11 + 20 + 36
            val showTranslation = !cueList && heightDp - fixed - 32 >= 56
            val ayahH = heightDp - fixed - (if (showTranslation) 32 else 0)
            val ayahW = widthDp - 28 - 12
            val font = root.optString("font", "lpmq")
            val pxW = (ayahW * density).toInt().coerceAtLeast(60)
            val pxH = (ayahH * density).toInt().coerceAtLeast(40)

            var shownItems = cueItems
            val bitmap = if (cueList) {
                val words = root.optInt("cueWords", 1)
                val (image, shown) = renderCue(
                    context,
                    cueItems.map { cueLine(it.optInt("n"), it.optString("ar"), words) },
                    font, pxW, pxH,
                )
                shownItems = cueItems.take(shown)
                image
            } else {
                renderAyah(context, next.optString("ar"), font, pxW, pxH, hidden)
            }
            views.setViewVisibility(R.id.hw_ayah, View.VISIBLE)
            views.setViewVisibility(R.id.hw_empty, View.GONE)
            views.setImageViewBitmap(R.id.hw_ayah, bitmap)
            views.setContentDescription(
                R.id.hw_ayah,
                if (cueList) "$name ayat ${shownItems.first().optInt("n")} sampai ${shownItems.last().optInt("n")}, kata awal saja"
                else "$name ayat $number",
            )
            // ketuk ayat = buka halaman hafalan surahnya (area terbesar -
            // harus membuka aplikasi); tutup/lihat hanya lewat tombolnya
            views.setOnClickPendingIntent(R.id.hw_ayah_box, open(context, surah))

            views.setViewVisibility(R.id.hw_translation, if (showTranslation && !hidden) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.hw_translation, next.optString("tr"))

            views.setTextViewText(R.id.hw_label, label(cueList, shownItems, number, total, widthDp))
            views.setViewVisibility(R.id.hw_peek, View.VISIBLE)
            views.setTextViewText(R.id.hw_peek, peekLabel(cueMode, peeking, hidden))
            views.setOnClickPendingIntent(R.id.hw_peek, broadcast(context, ACTION_PEEK, null, 1))
            views.setViewVisibility(R.id.hw_done, View.VISIBLE)
            views.setTextViewText(R.id.hw_done, if (cueMode) "✓ Ayat $number" else "✓ Hafal")
            views.setOnClickPendingIntent(
                R.id.hw_done,
                broadcast(context, ACTION_HAFAL, Uri.parse("rinduramadan://hafalan/set?ayah=${next.optInt("i")}"), 2),
            )
            return views
        }

        /// Kepala widget: surah yang dihafal, ditambah jumlah muraja'ah yang
        /// jatuh tempo hari ini bila ada.
        internal fun kicker(name: String, due: Int): String =
            "HAFALAN · ${name.uppercase()}" + if (due > 0) " · $due MURAJA'AH" else ""

        private fun label(cueList: Boolean, items: List<JSONObject>, number: Int, total: Int, widthDp: Int): String =
            if (cueList && items.size > 1) {
                val range = "${items.first().optInt("n")}-${items.last().optInt("n")}"
                if (widthDp >= 230) "Ayat $range dari $total" else "Ayat $range"
            } else if (widthDp >= 230) "Ayat $number dari $total" else "Ayat $number"

        internal fun peekLabel(cueMode: Boolean, peeking: Boolean, hidden: Boolean): String = when {
            cueMode -> if (peeking) "Tutup" else "Intip"
            else -> if (hidden) "Lihat" else "Tutup"
        }

        /** Satu ayat petunjuk: nomor ayat, kata-kata awal, dan apakah ada yang disembunyikan. */
        internal data class CueLine(val prefix: String, val words: String, val more: Boolean)

        /** "12" -> "١٢". */
        internal fun arabicDigits(n: Int): String =
            n.toString().map { '\u0660' + (it - '0') }.joinToString("")

        /** [words] kata pertama ayat [ar] (1..3) dengan nomor ayat [n]. */
        internal fun cueLine(n: Int, ar: String, words: Int): CueLine {
            val parts = ar.trim().split(Regex("\\s+"))
            val k = words.coerceIn(1, 3)
            return CueLine("(${arabicDigits(n)})", parts.take(k).joinToString(" "), parts.size > k)
        }

        /** Spasi tak terputus: nomor & kata awal satu ayat tidak terpisah baris. */
        private const val NBSP = '\u00A0'

        /** Teks satu ayat petunjuk tanpa nomor: kata awal (+ "…" bila ada sisanya). */
        internal fun cueWords(line: CueLine): String =
            line.words.replace(' ', NBSP) + if (line.more) "$NBSP…" else ""

        /**
         * Petunjuk mengalir seperti paragraf: ayat demi ayat bersambung dan
         * baru turun bila baris penuh (nomor emas, kata awal krem, "…" samar),
         * rata tengah, sebesar mungkin.
         *
         * Semua ayat diutamakan muat pada [CUE_MIN_SP] ke atas; bila tidak,
         * ayat di ujung dilepas agar teks tetap terbaca. Mengembalikan gambar
         * & jumlah ayat yang benar-benar tampil.
         */
        internal fun renderCue(context: Context, lines: List<CueLine>, font: String, w: Int, h: Int): Pair<Bitmap, Int> {
            val metrics = context.resources.displayMetrics
            val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = typeface(context, font)
                color = CREAM
            }
            var fit: StaticLayout? = null
            var shown = lines.size
            search@ while (shown >= 1) {
                val text = cueText(lines.take(shown))
                var sp = 34f
                while (sp >= CUE_MIN_SP) {
                    paint.textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sp, metrics)
                    // font mushaf berjarak baris lebar; petunjuk pendek aman dirapatkan
                    val l = build(text, paint, w, Int.MAX_VALUE, spacing = CUE_LINE_SPACING, pad = false)
                    if (l.height <= h) {
                        fit = l
                        break@search
                    }
                    sp -= 1f
                }
                shown--
            }
            // panel sangat pendek: satu ayat saja pada ukuran terkecil
            val layout = fit ?: build(cueText(lines.take(1)), paint, w, 1)
            shown = max(1, shown)
            val bitmap = Bitmap.createBitmap(w, max(1, min(h, layout.height)), Bitmap.Config.ARGB_8888)
            layout.draw(Canvas(bitmap))
            return bitmap to shown
        }

        private fun cueText(lines: List<CueLine>): CharSequence {
            val text = android.text.SpannableStringBuilder()
            lines.forEachIndexed { i, l ->
                if (i > 0) text.append("  ")
                val start = text.length
                text.append(l.prefix)
                text.setSpan(ForegroundColorSpan(GOLD), start, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                text.append(NBSP).append(cueWords(l))
                if (l.more) {
                    text.setSpan(
                        ForegroundColorSpan(0x99F4F1EA.toInt()),
                        text.length - 1,
                        text.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
                    )
                }
            }
            return text
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

        private fun build(
            text: CharSequence,
            paint: TextPaint,
            w: Int,
            maxLines: Int,
            align: Layout.Alignment = Layout.Alignment.ALIGN_CENTER,
            spacing: Float = 1.05f,
            pad: Boolean = true,
        ): StaticLayout =
            if (Build.VERSION.SDK_INT >= 23) {
                StaticLayout.Builder.obtain(text, 0, text.length, paint, w)
                    .setAlignment(align)
                    .setTextDirection(TextDirectionHeuristics.RTL)
                    .setLineSpacing(0f, spacing)
                    .setIncludePad(pad)
                    .setMaxLines(maxLines)
                    .setEllipsize(if (maxLines == Int.MAX_VALUE) null else TextUtils.TruncateAt.END)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                StaticLayout(text, paint, w, align, spacing, 0f, pad)
            }
    }
}
