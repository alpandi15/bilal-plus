package com.rinduramadan.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/**
 * Widget hitung mundur Ramadan: hanya jumlah hari (tanpa jam berjalan) plus
 * narasi pendek - padanan ringkas `RamadanCountdown` di aplikasi. Tiga
 * fase: menuju Ramadan, selama Ramadan, dan suasana Idulfitri (Maghrib hari
 * terakhir Ramadan sampai Maghrib 3 Syawal).
 *
 * Datanya (`ramadan_json`) ditulis Flutter lewat `home_widget_service_io.dart`
 * dari jangkar kalender hijriah yang sama dengan aplikasi: Ramadan yang baru
 * selesai (untuk fase Idulfitri), yang relevan sekarang, dan berikutnya,
 * masing-masing dengan `startsAt` = Maghrib
 * malam sebelum tanggal 1 (saat hari hijriah berganti). Hari Ramadan ke-n
 * juga berganti saat Maghrib - Maghrib hari ini dibaca dari `schedule_json`
 * milik widget jadwal sholat bila tersedia.
 */
private class RamadanItem(
    val hijriYear: Int,
    val startJdn: Int,
    val endJdn: Int,
    val days: Int,
    val estimated: Boolean,
    val tentative: Boolean,
    val overridden: Boolean,
    val startsAt: Long,
    val startShort: String,
    val endShort: String,
)

class RamadanWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val options = appWidgetManager.getAppWidgetOptions(id)
            appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, options, System.currentTimeMillis()))
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
        private const val DAY_MS = 24L * 60 * 60 * 1000

        /** Lama suasana Idulfitri (1-3 Syawal) - sama dengan `eidDays` di Flutter. */
        private const val EID_DAYS = 3
        private val BULAN = arrayOf(
            "Januari", "Februari", "Maret", "April", "Mei", "Juni",
            "Juli", "Agustus", "September", "Oktober", "November", "Desember",
        )

        /** Julian Day Number dari tanggal Masehi - sama dengan `gregorianToJdn` di Flutter. */
        private fun jdn(y: Int, m: Int, d: Int): Int {
            val a = (m - 14) / 12
            return (1461 * (y + 4800 + a)) / 4 + (367 * (m - 2 - 12 * a)) / 12 -
                (3 * ((y + 4900 + a) / 100)) / 4 + d - 32075
        }

        private fun parseYmd(s: String): Triple<Int, Int, Int> {
            val p = s.split("-")
            return Triple(p[0].toInt(), p[1].toInt(), p[2].toInt())
        }

        /** "8 Feb 2027" - muat di pil tanggal widget 2x2. */
        private fun shortLabelOf(ymd: String): String {
            val (y, m, d) = parseYmd(ymd)
            return "$d ${BULAN[m - 1].take(3)} $y"
        }

        private fun parse(json: String?): Pair<String, List<RamadanItem>>? {
            if (json.isNullOrEmpty()) return null
            return try {
                val root = JSONObject(json)
                val arr = root.getJSONArray("items")
                val items = (0 until arr.length()).map { i ->
                    val o = arr.getJSONObject(i)
                    val (sy, sm, sd) = parseYmd(o.getString("start"))
                    val (ey, em, ed) = parseYmd(o.getString("end"))
                    RamadanItem(
                        hijriYear = o.getInt("hijriYear"),
                        startJdn = jdn(sy, sm, sd),
                        endJdn = jdn(ey, em, ed),
                        days = o.getInt("days"),
                        estimated = o.optBoolean("estimated", false),
                        tentative = o.optBoolean("tentative", false),
                        overridden = o.optBoolean("overridden", false),
                        startsAt = o.getLong("startsAt"),
                        startShort = shortLabelOf(o.getString("start")),
                        endShort = shortLabelOf(o.getString("end")),
                    )
                }
                if (items.isEmpty()) null else root.optString("tzId", "Asia/Jakarta") to items
            } catch (_: Exception) {
                null
            }
        }

        /** Narasi menuju Ramadan, bertingkat menurut sisa hari. */
        // narasi dibatasi ±45 huruf agar muat 2 baris di widget selebar 2 sel
        private fun noteBefore(days: Int): String = when {
            days > 100 -> "Hati yang bersiap tak pernah terlalu dini."
            days > 30 -> "Lunasi utang puasa sebelum tamu agung tiba."
            days > 7 -> "Sebentar lagi. Rapikan niat, siapkan diri."
            days > 1 -> "Tinggal hitungan hari. Marhaban ya Ramadan."
            days == 1 -> "Mulai nanti Maghrib. Marhaban ya Ramadan."
            else -> "Malam pertama. Selamat menunaikan tarawih."
        }

        /** Keterangan status tanggal, sama dengan `RamadanDate.statusLabel` di Flutter. */
        private fun statusSuffix(r: RamadanItem): String = when {
            r.overridden -> " · pilihanmu"
            r.estimated -> " · perkiraan"
            r.tentative -> " · menunggu isbat"
            else -> ""
        }

        /** Narasi selama Ramadan: tiga fase sepuluh hari. */
        private fun noteDuring(day: Int): String = when {
            day <= 10 -> "Sepuluh hari pertama, penuh rahmat."
            day <= 20 -> "Sepuluh hari kedua, perbanyak istighfar."
            else -> "Sepuluh hari terakhir, raih Lailatul Qadar."
        }

        fun buildViews(context: Context, prefs: SharedPreferences, options: Bundle, now: Long): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.ramadan_widget_layout)
            views.setOnClickPendingIntent(
                R.id.ramadan_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            // Ukuran menentukan apa yang tampil, supaya tak ada teks terpotong:
            // - sempit (< 140dp, 1-2 sel kecil): angka mengecil, satuan pindah
            //   ke baris judul, tanggal & status disembunyikan
            // - pendek (< 140dp): tanggal disembunyikan; narasi hanya >= 190dp
            // - status tanggal (perkiraan / pilihanmu) hanya bila cukup lebar
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 160
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 150
            val narrow = widthDp < 140
            val short = heightDp < 140
            val compact = narrow || short
            val pad = ((if (compact) 12 else 16) * context.resources.displayMetrics.density).toInt()
            views.setViewPadding(R.id.ramadan_content, pad, pad * 7 / 8, pad, pad * 7 / 8)
            views.setTextViewTextSize(
                R.id.ramadan_number,
                TypedValue.COMPLEX_UNIT_SP,
                if (narrow) 34f else if (short) 38f else 46f,
            )
            views.setViewVisibility(R.id.ramadan_unit, if (narrow) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.ramadan_date, if (compact) View.GONE else View.VISIBLE)
            views.setViewVisibility(R.id.ramadan_note, if (compact || heightDp < 190) View.GONE else View.VISIBLE)
            val showStatus = widthDp >= 200

            /** Isi teks; di widget sempit satuan menjadi judul & kepala dipendekkan. */
            fun fill(
                kicker: String,
                shortKicker: String,
                number: String,
                unit: String,
                title: String,
                shortTitle: String,
            ) {
                views.setTextViewText(R.id.ramadan_kicker, if (narrow) shortKicker else kicker)
                views.setTextViewText(R.id.ramadan_number, number)
                views.setTextViewText(R.id.ramadan_unit, unit)
                views.setTextViewText(
                    R.id.ramadan_title,
                    if (narrow) shortTitle else title,
                )
            }

            val parsed = parse(prefs.getString("ramadan_json", null))
            if (parsed == null) {
                fill("MENUJU RAMADAN", "RAMADAN", "—", "HARI\nLAGI", "Ramadan", "Hari lagi")
                views.setTextViewText(R.id.ramadan_date, "Buka aplikasi")
                views.setTextViewText(R.id.ramadan_note, "")
                return views
            }
            val (tzId, items) = parsed

            val cal = Calendar.getInstance(TimeZone.getTimeZone(tzId)).apply { timeInMillis = now }
            val todayJdn = jdn(cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH))

            // Maghrib hari ini dari jadwal sholat (bila ada): hari hijriah berganti saat itu
            val schedule = WidgetData.parse(prefs.getString("schedule_json", null))
            val afterMaghrib = schedule?.let { WidgetState(it, now) }
                ?.takeIf { !it.stale }
                ?.let { now >= it.today.times["maghrib"]!! } ?: false

            // Suasana Idulfitri: sejak Maghrib hari terakhir Ramadan (malam
            // takbiran = 1 Syawal) sampai Maghrib 3 Syawal
            val shift = if (afterMaghrib) 1 else 0
            val eid = items.firstOrNull { (todayJdn - it.endJdn + 1 + shift) in 1..EID_DAYS }
            if (eid != null) {
                val syawal = todayJdn - eid.endJdn + 1 + shift
                fill(
                    "IDULFITRI ${eid.hijriYear} H", "IDULFITRI", "$syawal", "SYAWAL",
                    if (todayJdn < eid.endJdn) "Malam takbiran" else "Selamat Idulfitri",
                    "Syawal",
                )
                views.setTextViewText(R.id.ramadan_date, "Idulfitri ${eid.endShort}")
                views.setTextViewText(R.id.ramadan_note, "Taqabbalallahu minna wa minkum.")
                return views
            }

            // Ramadan pertama yang Idulfitrinya masih di depan
            val r = items.firstOrNull { it.endJdn > todayJdn } ?: items.last()
            val status = if (showStatus) statusSuffix(r) else ""
            val started = now >= r.startsAt

            if (!started) {
                // sama persis dengan kartu di aplikasi: sisa waktu sampai Maghrib
                // malam sebelum 1 Ramadan, dibulatkan ke bawah per 24 jam - bukan
                // selisih tanggal kalender (yang lebih besar 1 sampai jam Maghrib)
                val days = ((r.startsAt - now) / DAY_MS).toInt().coerceAtLeast(0)
                fill("MENUJU RAMADAN", "RAMADAN", "$days", "HARI\nLAGI", "Ramadan ${r.hijriYear} H", "Hari lagi")
                views.setTextViewText(R.id.ramadan_date, "Mulai ${r.startShort}$status")
                views.setTextViewText(R.id.ramadan_note, noteBefore(days))
            } else {
                val day = (todayJdn - r.startJdn + 1 + (if (afterMaghrib) 1 else 0)).coerceIn(1, r.days)
                fill("RAMADAN ${r.hijriYear} H", "RAMADAN", "$day", "HARI\nRAMADAN", "Selamat berpuasa", "Hari puasa")
                views.setTextViewText(R.id.ramadan_date, "Idulfitri ${r.endShort}$status")
                views.setTextViewText(R.id.ramadan_note, noteDuring(day))
            }
            return views
        }
    }
}
