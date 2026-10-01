package com.rinduramadan.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Paint
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/**
 * Widget Ibadah Harian: kemajuan hari ini, lima waktu yang bisa dicentang
 * langsung, dan ibadah lainnya - padanan ringkas halaman Ibadah Harian.
 *
 * Datanya (`ibadah_json`) disusun Flutter (`tracker_widget_payload.dart`):
 * hari ini DAN besok, supaya lewat tengah malam checklist baru langsung
 * tampil walau aplikasi belum dibuka.
 *
 * Mencentang dari widget:
 * 1. ketukan dikirim ke provider ini ([ACTION_SET]) - perubahannya langsung
 *    disimpan sebagai "tertunda" & widget digambar ulang (terasa instan),
 * 2. lalu diteruskan ke callback Dart di latar (`trackerWidgetCallback`,
 *    lewat home_widget) yang menulis ke basis data dan memperbarui
 *    `ibadah_json`,
 * 3. catatan tertunda dibuang begitu `ibadah_json` yang lebih baru tiba.
 */
class IbadahWidgetProvider : HomeWidgetProvider() {

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

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_SET) {
            val uri = intent.data ?: return
            val date = uri.getQueryParameter("date") ?: return
            val item = uri.getQueryParameter("item")?.toIntOrNull() ?: return
            val value = uri.getQueryParameter("value")?.toIntOrNull() ?: return
            setPending(context, date, item, value)
            refreshAll(context)
            // tulis ke basis data lewat Dart di latar
            HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
            return
        }
        super.onReceive(context, intent)
    }

    companion object {
        const val ACTION_SET = "com.rinduramadan.app.IBADAH_SET"
        private const val PENDING_PREFS = "tracker_widget_pending"
        private const val PENDING_KEY = "ibadah"
        private const val MAX_ROWS = 7

        private val SHOLAT_IDS = listOf(
            Triple(R.id.ib_sholat_0, R.id.ib_sholat_dot_0, R.id.ib_sholat_name_0),
            Triple(R.id.ib_sholat_1, R.id.ib_sholat_dot_1, R.id.ib_sholat_name_1),
            Triple(R.id.ib_sholat_2, R.id.ib_sholat_dot_2, R.id.ib_sholat_name_2),
            Triple(R.id.ib_sholat_3, R.id.ib_sholat_dot_3, R.id.ib_sholat_name_3),
            Triple(R.id.ib_sholat_4, R.id.ib_sholat_dot_4, R.id.ib_sholat_name_4),
        )
        private val ROW_IDS = listOf(
            intArrayOf(R.id.ib_row_0, R.id.ib_row_name_0, R.id.ib_row_meta_0, R.id.ib_row_check_0),
            intArrayOf(R.id.ib_row_1, R.id.ib_row_name_1, R.id.ib_row_meta_1, R.id.ib_row_check_1),
            intArrayOf(R.id.ib_row_2, R.id.ib_row_name_2, R.id.ib_row_meta_2, R.id.ib_row_check_2),
            intArrayOf(R.id.ib_row_3, R.id.ib_row_name_3, R.id.ib_row_meta_3, R.id.ib_row_check_3),
            intArrayOf(R.id.ib_row_4, R.id.ib_row_name_4, R.id.ib_row_meta_4, R.id.ib_row_check_4),
            intArrayOf(R.id.ib_row_5, R.id.ib_row_name_5, R.id.ib_row_meta_5, R.id.ib_row_check_5),
            intArrayOf(R.id.ib_row_6, R.id.ib_row_name_6, R.id.ib_row_meta_6, R.id.ib_row_check_6),
        )

        private class Entry(
            val id: Int,
            val name: String,
            val kind: String,
            var value: Int,
            val target: Int,
            var done: Boolean,
            val excused: Boolean,
            val at: Long,
            /** Akhir waktu sholat (epoch ms; 0 bila bukan sholat wajib). */
            val end: Long,
            val time: String,
            /** onTime / late / qadha - hanya bila pencatatan waktu sholat aktif. */
            var status: String?,
            val prayed: String,
            /** Bobot saat tuntas: sholat wajib sendiri < 1 (lihat ibadah_day.dart). */
            val weight: Double,
        )

        private fun entries(arr: JSONArray?): MutableList<Entry> {
            if (arr == null) return mutableListOf()
            return (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                Entry(
                    id = o.getInt("id"),
                    name = o.getString("name"),
                    kind = o.optString("kind", "check"),
                    value = o.optInt("value", 0),
                    target = o.optInt("target", 1),
                    done = o.optBoolean("done", false),
                    excused = o.optBoolean("excused", false),
                    at = o.optLong("at", 0L),
                    end = o.optLong("end", 0L),
                    time = o.optString("time", ""),
                    status = o.optString("status", "").ifEmpty { null },
                    prayed = o.optString("prayed", ""),
                    weight = o.optDouble("w", 1.0),
                )
            }.toMutableList()
        }

        /* ------------------------- catatan tertunda ------------------------- */

        private fun pendingPrefs(context: Context) =
            context.getSharedPreferences(PENDING_PREFS, Context.MODE_PRIVATE)

        private fun setPending(context: Context, date: String, item: Int, value: Int) {
            val prefs = pendingPrefs(context)
            val all = JSONObject(prefs.getString(PENDING_KEY, "{}") ?: "{}")
            all.put("$date|$item", JSONObject().put("v", value).put("t", System.currentTimeMillis()))
            prefs.edit().putString(PENDING_KEY, all.toString()).apply()
        }

        /**
         * Catatan tertunda yang belum tercermin di `ibadah_json` ([generatedAt]).
         * Dipakai juga widget Semangat Sholat agar centang dari widget ini
         * langsung terlihat di sana.
         */
        internal fun pending(context: Context, generatedAt: Long): Map<String, Int> {
            val prefs = pendingPrefs(context)
            val all = JSONObject(prefs.getString(PENDING_KEY, "{}") ?: "{}")
            val live = JSONObject()
            val result = mutableMapOf<String, Int>()
            all.keys().forEach { k ->
                val o = all.getJSONObject(k)
                if (o.getLong("t") > generatedAt) {
                    live.put(k, o)
                    result[k] = o.getInt("v")
                }
            }
            if (live.length() != all.length()) {
                prefs.edit().putString(PENDING_KEY, live.toString()).apply()
            }
            return result
        }

        private fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, IbadahWidgetProvider::class.java))
            val prefs = HomeWidgetPlugin.getData(context)
            val now = System.currentTimeMillis()
            ids.forEach { id ->
                manager.updateAppWidget(id, buildViews(context, prefs, manager.getAppWidgetOptions(id), now))
            }
            // widget Semangat Sholat memakai data yang sama
            SemangatWidgetProvider.refreshAll(context)
        }

        /* ------------------------------ intent ------------------------------ */

        private fun setIntent(context: Context, date: String, item: Int, value: Int): PendingIntent {
            val uri = Uri.parse("rinduramadan://ibadah/set?date=$date&item=$item&value=$value")
            val intent = Intent(context, IbadahWidgetProvider::class.java).apply {
                action = ACTION_SET
                data = uri
            }
            return PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun openApp(context: Context, page: String): PendingIntent =
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rinduramadan://$page"),
            )

        /* ------------------------------ gambar ------------------------------ */

        fun buildViews(context: Context, prefs: SharedPreferences, options: Bundle, now: Long): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.ibadah_widget_layout)
            views.setOnClickPendingIntent(R.id.ib_root, openApp(context, "ibadah"))
            views.setOnClickPendingIntent(R.id.ib_more, openApp(context, "ibadah"))

            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 220
            // sempit (< 140dp): teks dipendekkan & diperkecil supaya tak ada yang terpotong
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 150
            val narrow = widthDp < 140

            val root = prefs.getString("ibadah_json", null)?.let {
                try { JSONObject(it) } catch (_: Exception) { null }
            }
            if (root == null) {
                empty(views, "Buka aplikasi untuk memulai")
                return views
            }

            val cal = Calendar.getInstance(TimeZone.getTimeZone(root.optString("tzId", "Asia/Jakarta")))
                .apply { timeInMillis = now }
            val today = "%04d-%02d-%02d".format(
                cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
            )
            val days = root.getJSONArray("days")
            val day = (0 until days.length()).map { days.getJSONObject(it) }
                .firstOrNull { it.getString("date") == today }
            if (day == null) {
                empty(views, "Buka aplikasi untuk memperbarui")
                return views
            }

            // terapkan centang yang belum dikonfirmasi basis data
            val pending = pending(context, root.optLong("generatedAt", 0L))
            val sholat = entries(day.optJSONArray("sholat"))
            val items = entries(day.optJSONArray("items"))
            var done = day.optInt("done", 0)
            var score = day.optDouble("score", done.toDouble())
            for (e in sholat + items) {
                val v = pending["$today|${e.id}"] ?: continue
                val nowDone = if (e.kind == "counter") v >= e.target else v > 0
                if (!e.excused && nowDone != e.done) {
                    done += if (nowDone) 1 else -1
                    score += if (nowDone) e.weight else -e.weight
                }
                e.value = v
                e.done = nowDone
                // status baru diketahui sesudah Dart mencatat jamnya
                if (!nowDone) e.status = null
            }
            val total = day.optInt("total", 0)
            val excused = day.optBoolean("excused", false)

            // kepala & kemajuan
            val kicker = day.optString("kicker", "IBADAH HARIAN")
            views.setTextViewText(
                R.id.ib_kicker,
                when {
                    !narrow -> kicker
                    // "RAMADAN · HARI 5" -> "RAMADAN 5", "SENIN · 28 SEP" -> "SENIN"
                    kicker.startsWith("RAMADAN · HARI ") -> "RAMADAN " + kicker.removePrefix("RAMADAN · HARI ")
                    else -> kicker.substringBefore(" · ")
                },
            )
            views.setTextViewText(R.id.ib_count, "$done/$total")
            // bar = nilai tertimbang (sholat sendiri bernilai lebih kecil)
            views.setProgressBar(
                R.id.ib_progress, 1000,
                if (total == 0) 0 else (score * 1000 / total).toInt().coerceIn(0, 1000), false,
            )
            val streak = day.optInt("streak", 0)
            val seed = cal.get(Calendar.DAY_OF_YEAR) * 7
            val onTimeMs = root.optInt("onTimeMinutes", 15) * 60_000L
            val message = when {
                excused -> if (narrow) "Berhalangan" else "Berhalangan · streak aman"
                total > 0 && done >= total -> pick(
                    if (narrow) listOf("Semua tuntas", "Masyaa Allah!")
                    else listOf(
                        "Masyaa Allah, semua tuntas hari ini",
                        "Alhamdulillah, semua tuntas. Istiqamah ya!",
                        "Semua tuntas - semoga Allah terima amalmu",
                    ),
                    seed,
                )
                else -> sholatMessage(sholat, now, onTimeMs, narrow, seed)
                    // tidak ada yang mendesak: motivasi sesuai waktu (pagi,
                    // Dhuha, siang, malam, jangan begadang), streak ikut
                    // bergiliran
                    ?: if (!narrow) {
                        val counted = sholat.filter { !it.excused }
                        val lines = WidgetMotivation.lines(
                            now,
                            WidgetMotivation.Times(
                                subuh = sholat.getOrNull(0)?.at ?: 0L,
                                sunrise = sholat.getOrNull(0)?.end ?: 0L,
                                dzuhur = sholat.getOrNull(1)?.at ?: 0L,
                                ashar = sholat.getOrNull(2)?.at ?: 0L,
                                maghrib = sholat.getOrNull(3)?.at ?: 0L,
                                isya = sholat.getOrNull(4)?.at ?: 0L,
                            ),
                            WidgetMotivation.status(
                                day.optJSONArray("items"),
                                pending,
                                today,
                                allSholat = counted.isNotEmpty() && counted.all { it.done },
                            ),
                            seed,
                        )
                        pick(
                            lines.short + listOfNotNull(
                                if (streak > 0) "🔥 $streak hari terjaga" else null,
                            ),
                            cal.get(Calendar.HOUR_OF_DAY),
                        )
                    } else when {
                        streak > 0 -> if (narrow) "🔥 $streak hari" else "🔥 $streak hari terjaga"
                        // "15 Rabiul Akhir 1448 H" -> tanpa tahun bila sempit
                        else -> day.optString("hijri", "").let {
                            if (narrow) it.replace(Regex("""\s+\d+\s*H$"""), "") else it
                        }
                    }
            }
            views.setTextViewText(R.id.ib_streak, message)
            val showMessage = heightDp >= 200
            views.setViewVisibility(R.id.ib_streak, if (showMessage) View.VISIBLE else View.GONE)
            // pesan panjang turun ke baris kedua - daftar di bawahnya menyesuaikan
            val twoLines = textWidthDp(context, message) > widthDp - 24

            // lima waktu: waktu yang sedang berjalan disorot. Bulatan mengisi
            // lebar kolomnya (maks. 24dp) - dipersempit lewat padding agar
            // tetap bulat & tak saling tumpuk di widget sempit.
            val currentId = sholat.lastOrNull { it.at in 1..now }?.id
            val density = context.resources.displayMetrics.density
            val colDp = (widthDp - 24) / sholat.size.coerceIn(1, 5).toFloat()
            val dotDp = (colDp - 3).coerceIn(12f, 24f)
            val padX = (((colDp - dotDp) / 2).coerceAtLeast(0f) * density).toInt()
            val padY = (((24 - dotDp) / 2) * density).toInt()
            SHOLAT_IDS.forEachIndexed { i, (col, dot, name) ->
                val e = sholat.getOrNull(i)
                if (e == null) {
                    views.setViewVisibility(col, View.GONE)
                    return@forEachIndexed
                }
                views.setViewVisibility(col, View.VISIBLE)
                views.setViewPadding(dot, padX, padY, padX, padY)
                views.setImageViewResource(
                    dot,
                    when {
                        e.excused -> R.drawable.tracker_dot_off
                        e.done -> R.drawable.tracker_dot_done
                        e.id == currentId -> R.drawable.tracker_dot_now
                        else -> R.drawable.tracker_dot_todo
                    },
                )
                val statusLabel = when (e.status) {
                    "onTime" -> ", awal waktu"
                    "late" -> ", terlambat"
                    "qadha" -> ", qadha"
                    else -> ""
                }
                views.setContentDescription(
                    dot,
                    "${e.name} ${e.time}" + (if (e.done) ", sudah" else "") + statusLabel,
                )
                // jam sholat yang dicatat menggantikan nama saat sudah dikerjakan;
                // di widget sempit cukup huruf awalnya
                views.setTextViewText(
                    name,
                    when {
                        narrow -> e.name.take(1)
                        e.done && e.prayed.isNotEmpty() -> e.prayed
                        else -> e.name
                    },
                )
                if (!e.excused) {
                    views.setOnClickPendingIntent(col, setIntent(context, today, e.id, if (e.done) 0 else 1))
                }
            }

            // ibadah lainnya: yang belum selesai di atas, sebanyak yang muat
            val used = 119 + (if (!showMessage) 0 else if (twoLines) 25 else 14)
            val capacity = ((heightDp - used) / 30).coerceIn(0, MAX_ROWS)
            val ordered = items.sortedBy { if (it.done || it.excused) 1 else 0 }
            ROW_IDS.forEachIndexed { i, ids ->
                val (row, name, meta, check) = ids.toList()
                val e = ordered.getOrNull(i)
                if (e == null || i >= capacity) {
                    views.setViewVisibility(row, View.GONE)
                    return@forEachIndexed
                }
                views.setViewVisibility(row, View.VISIBLE)
                views.setTextViewText(name, e.name)
                views.setTextColor(name, if (e.excused) 0x80F4F1EA.toInt() else 0xFFF4F1EA.toInt())
                // sempit: nama dua baris lebih kecil, hitungan x/y disembunyikan
                views.setInt(name, "setMaxLines", if (narrow) 2 else 1)
                views.setTextViewTextSize(name, TypedValue.COMPLEX_UNIT_SP, if (narrow) 9.5f else 11f)
                if (narrow) {
                    views.setViewVisibility(meta, View.GONE)
                    views.setViewVisibility(check, View.VISIBLE)
                } else if (e.kind == "counter") {
                    views.setViewVisibility(meta, View.VISIBLE)
                    views.setTextViewText(meta, "${e.value}/${e.target}")
                    views.setViewVisibility(check, if (e.done) View.VISIBLE else View.GONE)
                } else {
                    views.setViewVisibility(meta, View.GONE)
                    views.setViewVisibility(check, View.VISIBLE)
                }
                views.setImageViewResource(
                    check,
                    when {
                        e.excused -> R.drawable.tracker_dot_off
                        e.done -> R.drawable.tracker_dot_done
                        else -> R.drawable.tracker_dot_todo
                    },
                )
                views.setOnClickPendingIntent(
                    row,
                    when {
                        // hitungan diisi di aplikasi; tilawah tercentang lewat catatan bacaan
                        e.excused || e.kind == "counter" -> openApp(context, "ibadah")
                        e.kind == "tilawah" -> openApp(context, "quran")
                        else -> setIntent(context, today, e.id, if (e.done) 0 else 1)
                    },
                )
            }

            val hidden = (ordered.size - capacity).coerceAtLeast(0)
            views.setTextViewText(
                R.id.ib_more,
                if (hidden > 0) "+$hidden lainnya ›" else "Buka checklist ›",
            )
            return views
        }

        private fun pick(variants: List<String>, seed: Int) = variants[Math.floorMod(seed, variants.size)]

        /** Lebar [text] (dp) pada ukuran 9sp - ukuran baris pesan. */
        private fun textWidthDp(context: Context, text: String): Float {
            val metrics = context.resources.displayMetrics
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, 9f, metrics)
            }
            return paint.measureText(text) / metrics.density
        }

        /**
         * Pesan penyemangat sholat (bervariasi per hari, bukan setiap
         * pembaruan): pengingat sholat yang sedang berjalan & belum dicentang,
         * lalu tanggapan atas sholat terakhir yang dicatat (terlambat/qadha
         * disemangati, awal waktu dipuji). Pengganti warna merah/oranye yang
         * tidak dipakai di widget. Null bila tidak ada yang perlu disampaikan.
         */
        private fun sholatMessage(
            sholat: List<Entry>,
            now: Long,
            onTimeMs: Long,
            narrow: Boolean,
            seed: Int,
        ): String? {
            val current = sholat.lastOrNull { it.at in 1..now }
            if (current != null && !current.done && !current.excused && current.end > now) {
                val n = current.name
                val s = seed + current.id
                return if (now <= current.at + onTimeMs) {
                    pick(
                        if (narrow) listOf("Yuk sholat $n", "Saatnya $n", "$n sudah masuk")
                        else listOf(
                            "Waktu $n sudah masuk. Yuk sholat di awal waktu.",
                            "Amalan paling dicintai Allah: sholat di awal waktu. Yuk $n!",
                            "Tinggalkan sejenak urusanmu, $n sudah memanggil.",
                            "Hayya 'alash-shalah - saatnya sholat $n.",
                            "Sebelum sibuk lagi, sholat $n dulu yuk.",
                        ),
                        s,
                    )
                } else {
                    pick(
                        if (narrow) listOf("$n belum sholat", "Jangan tunda $n")
                        else listOf(
                            "Awal waktu $n sudah lewat. Jangan tunda lagi, sholat sekarang.",
                            "Waktu $n masih ada - tunaikan sekarang sebelum terlewat.",
                            "Urusan lain bisa menunggu, $n tidak. Sholat sekarang ya.",
                        ),
                        s,
                    )
                }
            }

            // terlewat hari ini (waktunya habis, belum dicentang): tegas, tapi
            // tetap membuka pintu - segera qadha & istighfar
            val missed = sholat.filter { it.end in 1..now && !it.done && !it.excused }
            if (missed.isNotEmpty()) {
                val n = if (missed.size == 1) missed.single().name else "${missed.size} sholat"
                return pick(
                    if (narrow) listOf("$n terlewat!", "Segera qadha $n")
                    else listOf(
                        "$n terlewat. Sholat itu kewajiban - segera qadha, jangan ditunda.",
                        "$n belum tertunai. Qadha sekarang lalu istighfar, Allah Maha Pengampun.",
                        "Lupa mencatat $n? Centang. Terlewat? Qadha sekarang juga.",
                    ),
                    seed + missed.first().id,
                )
            }

            // tanggapan hanya ±2 jam setelah waktu sholatnya
            val last = sholat.lastOrNull { it.done }
                ?.takeIf { now < minOf(it.end, it.at + 2 * 60 * 60_000L) }
                ?: return null
            val n = last.name
            val next = sholat.firstOrNull { it.at > last.at && !it.done && !it.excused }?.name
            val s = seed + last.id
            return when (last.status) {
                "late" -> pick(
                    if (narrow) listOf("Next di awal waktu", "Jangan telat lagi")
                    else if (next != null) listOf(
                        "$n tadi terlambat. $next harus di awal waktu ya.",
                        "Jangan biasakan terlambat - siap-siap sebelum adzan $next.",
                        "Pasang niat & alarm sebelum adzan $next, jangan telat lagi.",
                    )
                    else listOf(
                        "$n tadi terlambat. Besok niatkan semua di awal waktu.",
                        "Jangan biasakan terlambat - esok semua di awal waktu ya.",
                    ),
                    s,
                )
                "qadha" -> pick(
                    if (narrow) listOf("Istighfar ya", "Jangan terulang ya")
                    else if (next != null) listOf(
                        "$n sudah diqadha. Istighfar, dan jaga $next di awal waktu.",
                        "Qadha bukan kebiasaan - sambut $next begitu adzan.",
                        "Pasang alarm sebelum $next, jangan sampai terlewat lagi.",
                    )
                    else listOf(
                        "$n sudah diqadha. Istighfar, besok jangan terulang.",
                        "Qadha bukan kebiasaan - pasang alarm untuk Subuh esok.",
                    ),
                    s,
                )
                "onTime" -> pick(
                    if (narrow) listOf("$n tepat waktu", "Masyaa Allah!")
                    else listOf(
                        "Masyaa Allah, $n di awal waktu!",
                        "Barakallahu fik, $n tepat waktu.",
                        "Istiqamah ya - $n di awal waktu.",
                    ),
                    s,
                )
                else -> null
            }
        }

        private fun empty(views: RemoteViews, message: String) {
            views.setTextViewText(R.id.ib_kicker, "IBADAH HARIAN")
            views.setTextViewText(R.id.ib_count, "")
            views.setProgressBar(R.id.ib_progress, 1000, 0, false)
            views.setTextViewText(R.id.ib_streak, message)
            views.setViewVisibility(R.id.ib_streak, View.VISIBLE)
            views.setViewVisibility(R.id.ib_sholat_row, View.GONE)
            ROW_IDS.forEach { views.setViewVisibility(it[0], View.GONE) }
            views.setTextViewText(R.id.ib_more, "Buka aplikasi ›")
        }
    }
}
