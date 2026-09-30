package com.rinduramadan.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Paint
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone
import kotlin.math.ceil

/**
 * Widget "Semangat Sholat" (3x2, bisa 4x2): satu pesan santai ala gen Z
 * sesuai keadaan sholat saat ini + checklist lima waktu (hanya tampilan).
 * Tidak ada tombol - ketukan di mana pun membuka halaman Ibadah.
 *
 * Pesannya tidak menghakimi: sholat yang terlewat/terlambat/qadha dijawab
 * dengan ajakan & semangat, bukan teguran. Urutan prioritas:
 * berhalangan > sholat berjalan belum dicentang > sebentar lagi masuk
 * (<= [SOON_MIN] menit) > puasa Tarwiyah/Arafah (& malam sebelumnya) >
 * lima waktu tuntas > ada yang terlewat hari ini >
 * tanggapan sholat terakhir (awal waktu/terlambat/qadha) > sholat berikutnya.
 * Variasi kalimat dipilih per hari (tidak berganti tiap refresh).
 *
 * Datanya sama dengan widget Ibadah Harian (`ibadah_json`, disusun
 * `tracker_widget_payload.dart`), termasuk centang tertunda dari widget itu.
 * Refresh dijadwalkan sendiri (AlarmManager tak-eksak): tiap ~5 menit
 * selama "X menit lalu/lagi" tampil, dan di setiap pergantian keadaan
 * (20 menit sebelum adzan, adzan, batas awal waktu, akhir waktu).
 */
class SemangatWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        update(context, appWidgetManager, appWidgetIds, widgetData)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        update(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(refreshIntent(context))
    }

    companion object {
        /** "Bentar lagi ..." mulai sekian menit sebelum adzan. */
        private const val SOON_MIN = 20
        private const val MINUTE = 60_000L
        private const val LIVE_REFRESH_MS = 5 * MINUTE
        private const val IDLE_REFRESH_MS = 30 * MINUTE

        private val DOTS = listOf(
            Triple(R.id.sw_col_0, R.id.sw_dot_0, R.id.sw_name_0),
            Triple(R.id.sw_col_1, R.id.sw_dot_1, R.id.sw_name_1),
            Triple(R.id.sw_col_2, R.id.sw_dot_2, R.id.sw_name_2),
            Triple(R.id.sw_col_3, R.id.sw_dot_3, R.id.sw_name_3),
            Triple(R.id.sw_col_4, R.id.sw_dot_4, R.id.sw_name_4),
        )

        private class Prayer(
            val id: Int,
            val name: String,
            val at: Long,
            val end: Long,
            val time: String,
            var done: Boolean,
            val excused: Boolean,
            var status: String?,
        )

        /** Isi widget saat ini: pesan & kapan perlu digambar ulang. */
        private class Mood(val message: String, val live: Boolean)

        private fun prayers(arr: JSONArray?): List<Prayer> {
            if (arr == null) return emptyList()
            return (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                Prayer(
                    id = o.getInt("id"),
                    name = o.getString("name"),
                    at = o.optLong("at", 0L),
                    end = o.optLong("end", 0L),
                    time = o.optString("time", ""),
                    done = o.optBoolean("done", false),
                    excused = o.optBoolean("excused", false),
                    status = o.optString("status", "").ifEmpty { null },
                )
            }
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, SemangatWidgetProvider::class.java))
            if (ids.isNotEmpty()) update(context, manager, ids, HomeWidgetPlugin.getData(context))
        }

        private fun update(
            context: Context,
            manager: AppWidgetManager,
            ids: IntArray,
            prefs: SharedPreferences,
        ) {
            val now = System.currentTimeMillis()
            ids.forEach { id ->
                manager.updateAppWidget(id, buildViews(context, prefs, manager.getAppWidgetOptions(id), now))
            }
            scheduleNextRefresh(context, prefs, now)
        }

        /* ------------------------------ data ------------------------------ */

        /** `ibadah_json` beserta data hari ini & besok. */
        private class Loaded(val root: JSONObject, val today: JSONObject, val tomorrow: JSONObject?)

        private fun load(prefs: SharedPreferences, now: Long): Loaded? {
            val root = prefs.getString("ibadah_json", null)?.let {
                try { JSONObject(it) } catch (_: Exception) { null }
            } ?: return null
            val cal = Calendar.getInstance(TimeZone.getTimeZone(root.optString("tzId", "Asia/Jakarta")))
                .apply { timeInMillis = now }
            val today = "%04d-%02d-%02d".format(
                cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
            )
            val days = root.optJSONArray("days") ?: return null
            val list = (0 until days.length()).map { days.getJSONObject(it) }
            val i = list.indexOfFirst { it.getString("date") == today }
            if (i < 0) return null
            return Loaded(root, list[i], list.getOrNull(i + 1))
        }

        /* ------------------------------ gambar ----------------------------- */

        fun buildViews(context: Context, prefs: SharedPreferences, options: Bundle, now: Long): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.semangat_widget_layout)
            views.setOnClickPendingIntent(
                R.id.sw_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("rinduramadan://ibadah")),
            )

            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 150
            // widget pendek: nama sholat di bawah bulatan disembunyikan
            val showNames = heightDp >= 130
            DOTS.forEach { (_, _, name) -> views.setViewVisibility(name, if (showNames) View.VISIBLE else View.GONE) }

            val loaded = load(prefs, now)
            if (loaded == null) {
                views.setTextViewText(R.id.sw_kicker, "SEMANGAT SHOLAT")
                views.setTextViewText(R.id.sw_count, "–/5")
                views.setTextViewText(R.id.sw_message, "Buka Bilal+ sebentar ya, biar widget ini ke-update ✨")
                DOTS.forEach { (col, _, _) -> views.setViewVisibility(col, View.GONE) }
                return views
            }

            val root = loaded.root
            val day = loaded.today

            // centang tertunda dari widget Ibadah Harian
            val sholat = prayers(day.optJSONArray("sholat"))
            val pending = IbadahWidgetProvider.pending(context, root.optLong("generatedAt", 0L))
            val date = day.getString("date")
            sholat.forEach { p ->
                val v = pending["$date|${p.id}"] ?: return@forEach
                if (v > 0 != p.done) {
                    p.done = v > 0
                    p.status = null
                }
            }
            val tomorrowSubuh = loaded.tomorrow?.let { prayers(it.optJSONArray("sholat")).firstOrNull() }
            val excused = day.optBoolean("excused", false)
            val onTimeMs = root.optInt("onTimeMinutes", 15) * MINUTE
            val seed = Calendar.getInstance().apply { timeInMillis = now }.get(Calendar.DAY_OF_YEAR) * 7

            views.setTextViewText(R.id.sw_kicker, day.optString("kicker", "SHOLAT HARI INI"))
            val counted = sholat.filter { !it.excused }
            views.setTextViewText(
                R.id.sw_count,
                if (excused || counted.isEmpty()) "rehat" else "${counted.count { it.done }}/${counted.size}",
            )

            // pesan: yang terpanjang yang muat di tinggi widget
            val maxLines = when {
                heightDp >= 170 -> 4
                heightDp >= 125 -> 3
                else -> 2
            }
            views.setInt(R.id.sw_message, "setMaxLines", maxLines)
            // widget pendek: huruf sedikit lebih kecil
            val textSp = if (heightDp < 130) 13f else 14f
            views.setTextViewTextSize(R.id.sw_message, TypedValue.COMPLEX_UNIT_SP, textSp)
            val room = (widthDp - 32).toFloat()
            // Hari Tarwiyah/Arafah (puasa sunnah) & malam sebelumnya
            val fastItem = day.optInt("fastItem", 0)
            var fastDone = day.optJSONArray("items")?.let { arr ->
                (0 until arr.length()).map { arr.getJSONObject(it) }
                    .firstOrNull { it.optInt("id") == fastItem }?.optBoolean("done", false)
            } ?: false
            pending["$date|$fastItem"]?.let { fastDone = it > 0 }
            val fast = Fast(
                today = day.optString("fast", "").ifEmpty { null },
                done = fastDone,
                tomorrow = loaded.tomorrow?.optString("fast", "")?.ifEmpty { null },
                maghrib = (sholat.firstOrNull { it.name == "Maghrib" } ?: sholat.getOrNull(3))?.at ?: 0L,
            )
            val msgs = messages(sholat, tomorrowSubuh, excused, now, onTimeMs, fast)
            val salt = seed + (sholat.firstOrNull { !it.done }?.id ?: 0)
            fun rotate(list: List<String>): List<String> {
                val start = Math.floorMod(salt, list.size)
                return list.drop(start) + list.take(start)
            }
            // kalimat panjang bila muat, versi singkat bila tidak
            val message = (rotate(msgs.long) + rotate(msgs.short))
                .firstOrNull { lines(context, it, room, textSp) <= maxLines }
                ?: msgs.short.minByOrNull { it.length }!!
            views.setTextViewText(R.id.sw_message, message)
            views.setContentDescription(R.id.sw_root, message)

            // lima waktu: hanya tampilan - tanpa warna "terlambat"
            val current = currentPrayer(sholat, now)
            DOTS.forEachIndexed { i, (col, dot, name) ->
                val p = sholat.getOrNull(i)
                if (p == null) {
                    views.setViewVisibility(col, View.GONE)
                    return@forEachIndexed
                }
                views.setViewVisibility(col, View.VISIBLE)
                views.setTextViewText(name, p.name)
                val isNow = p == current && !p.done && !p.excused
                views.setImageViewResource(
                    dot,
                    when {
                        p.excused -> R.drawable.tracker_dot_off
                        p.done -> R.drawable.tracker_dot_done
                        isNow -> R.drawable.tracker_dot_now
                        else -> R.drawable.tracker_dot_todo
                    },
                )
                views.setTextColor(name, if (isNow) 0xFFF2D38A.toInt() else 0xFFB9D3CB.toInt())
            }
            return views
        }

        /** Sholat yang waktunya sedang berjalan. */
        private fun currentPrayer(sholat: List<Prayer>, now: Long): Prayer? =
            sholat.lastOrNull { it.at in 1..now }?.takeIf { it.end > now }

        private fun minutes(ms: Long) = (ms / MINUTE).coerceAtLeast(1)

        /** Variasi pesan keadaan saat ini: [long] biasa & [short] untuk widget kecil. */
        private class Messages(val long: List<String>, val short: List<String>)

        /** Puasa Tarwiyah/Arafah hari ini ([today]) / besok ([tomorrow]): "tarwiyah" / "arafah". */
        private class Fast(val today: String?, val done: Boolean, val tomorrow: String?, val maghrib: Long)

        private fun messages(
            sholat: List<Prayer>,
            tomorrowSubuh: Prayer?,
            excused: Boolean,
            now: Long,
            onTimeMs: Long,
            fast: Fast,
        ): Messages {
            if (excused) {
                return Messages(
                    listOf(
                        "Lagi berhalangan, santai dulu ya 🌸 Dzikir tetap jalan biar hati adem.",
                        "Rehat dulu, it's okay 🌸 Tetap jaga dzikir & doa ya.",
                        "Lagi libur sholat, istirahat yang cukup 🌸 Nanti kita gas bareng lagi.",
                    ),
                    listOf("Lagi rehat dulu ya 🌸", "Santai dulu, dzikir jalan 🌸"),
                )
            }
            // sholat berjalan & belum dicentang
            val current = currentPrayer(sholat, now)
            if (current != null && !current.done && !current.excused) {
                val n = current.name
                val m = minutes(now - current.at)
                if (now <= current.at + onTimeMs) {
                    return Messages(
                        listOf(
                            "$n udah masuk $m menit lalu. Sebelum sibuk lagi, sholat dulu yuk 🙌",
                            "Psst, $n udah mulai nih. Pause dulu scroll-nya, sholat bentar yuk 📿",
                            "Waktunya $n~ ambil wudhu dulu, sisanya bisa nanti 💧",
                            "Adzan $n udah $m menit lalu. Gas sekarang, masih awal waktu kok ⏰",
                            "$n udah on! Lima menit buat Allah, hati auto adem ✨",
                        ),
                        listOf("$n udah masuk, yuk sholat 🙌", "Waktunya $n, gas wudhu 💧"),
                    )
                }
                val until = hm(current.end, sholat, tomorrowSubuh)
                return Messages(
                    listOf(
                        "$n tinggal sampai $until. Jangan ditunda lagi, sholat sekarang ya 🙏",
                        "Awal waktu $n udah lewat. Berhenti dulu, sholat sekarang sebelum habis 💪",
                        "$n belum ditunaikan, waktunya sampai $until. Urusan lain bisa nunggu, sholat nggak 🕰️",
                    ),
                    listOf("Sholat $n sekarang 🙏", "Jangan tunda $n lagi 💪"),
                )
            }

            // sebentar lagi masuk
            val next = sholat.firstOrNull { it.at > now } ?: tomorrowSubuh?.takeIf { it.at > now }
            if (next != null && next.at - now <= SOON_MIN * MINUTE) {
                val n = next.name
                val m = minutes(next.at - now + MINUTE - 1)
                return Messages(
                    listOf(
                        "Bentar lagi $n, $m menit lagi. Siap-siap wudhu yuk 💧",
                        "$m menit lagi $n nih. Wrap up dulu kerjaannya ya ✨",
                        "Heads up: $n $m menit lagi. Biar bisa on time 🕰️",
                    ),
                    listOf("$n $m menit lagi, siap-siap 💧", "Bentar lagi $n ✨"),
                )
            }

            // puasa Tarwiyah/Arafah - sesudah urusan sholat yang mendesak
            fastMessages(fast, now)?.let { return it }

            val counted = sholat.filter { !it.excused }
            if (counted.isNotEmpty() && counted.all { it.done }) {
                val c = "${counted.size}/${counted.size}"
                return Messages(
                    listOf(
                        "$c hari ini, masyaa Allah 🔥 Kamu keren!",
                        "Lima waktu beres semua ✨ Istirahat yang tenang ya.",
                        "Full combo $c 🏆 Semoga Allah terima semuanya.",
                    ),
                    listOf("$c, masyaa Allah 🔥", "Full combo hari ini 🏆"),
                )
            }

            // terlewat hari ini (waktunya habis, belum dicentang)
            val missed = sholat.filter { it.end in 1..now && !it.done && !it.excused }
            if (missed.size > 1) {
                val c = missed.size
                return Messages(
                    listOf(
                        "$c sholat terlewat. Itu utang ke Allah, qadha sekarang ya, jangan ditunda 🤲",
                        "Ada $c sholat terlewat. Segera qadha, lalu istighfar. Allah Maha Penerima taubat 🤍",
                        "$c sholat belum dicentang. Lupa mencatat? Centang. Terlewat? Qadha sekarang 🙏",
                    ),
                    listOf("$c sholat terlewat, qadha sekarang 🤲", "Segera qadha $c sholat 🙏"),
                )
            }
            if (missed.size == 1) {
                val n = missed.single().name
                return Messages(
                    listOf(
                        "$n terlewat. Sholat itu kewajiban, qadha sekarang ya, jangan ditunda 🤲",
                        "$n belum tertunai. Segera qadha, lalu istighfar. Allah Maha Penerima taubat 🤍",
                        "$n belum dicentang. Lupa mencatat? Centang. Terlewat? Qadha sekarang 🙏",
                    ),
                    listOf("$n terlewat, qadha sekarang 🤲", "Segera qadha $n 🙏"),
                )
            }

            // tanggapan sholat terakhir yang dicatat
            val last = sholat.lastOrNull { it.done && !it.excused }
            val upcoming = next?.name
            if (last != null) {
                val n = last.name
                when (last.status) {
                    "late" -> return Messages(
                        if (upcoming != null) listOf(
                            "$n udah tertunai, tapi telat. $upcoming harus di awal waktu ya ⏰",
                            "$n tertunai ✅ tapi telat. Siap-siap sebelum adzan $upcoming, pasti bisa!",
                            "Alhamdulillah $n tertunai. Pasang alarm buat $upcoming, jangan sampai telat lagi 🙌",
                        ) else listOf(
                            "$n tertunai ✅ tapi telat. Besok niatkan semua di awal waktu ya ✨",
                            "Alhamdulillah $n tertunai. Besok jangan sampai telat lagi ya 🙌",
                        ),
                        listOf("$n telat, next awal waktu ⏰", "Next jangan telat lagi ya ✅"),
                    )
                    "qadha" -> return Messages(
                        listOf(
                            "$n udah diqadha 🤍 Istighfar, dan jangan sampai terlewat lagi ya.",
                            "$n udah dibayar 🫡 Tapi qadha bukan kebiasaan" +
                                (upcoming?.let { ", $it harus tepat waktu." } ?: ", besok tepat waktu."),
                        ),
                        listOf("$n diqadha, jangan terulang 🤍", "Istighfar, next tepat waktu 🫡"),
                    )
                    "onTime" -> return Messages(
                        listOf(
                            "$n on time, keren banget! Pertahanin vibes-nya ✨",
                            "Masyaa Allah, $n tepat waktu 🔥 Keep it up!",
                            "$n di awal waktu ✅ Kamu lagi di jalur yang bener nih.",
                        ),
                        listOf("$n on time, keren! ✨", "$n tepat waktu 🔥"),
                    )
                }
            }

            // bawaan: sholat berikutnya
            if (next != null) {
                val t = next.time.ifEmpty { hm(next.at, sholat, tomorrowSubuh) }
                return Messages(
                    listOf(
                        "Next up: ${next.name} jam $t. Santai dulu, pas adzan langsung gas ✨",
                        "${next.name} jam $t. Sambil nunggu, dzikir dikit yuk 📿",
                        "Siap-siap ${next.name} jam $t. Kamu pasti bisa on time 💪",
                    ),
                    listOf("Next: ${next.name} jam $t ✨", "${next.name} jam $t, siap-siap 💪"),
                )
            }
            return Messages(listOf("Semoga harimu adem & penuh berkah ✨"), listOf("Have a blessed day ✨"))
        }

        private fun fastMessages(fast: Fast, now: Long): Messages? {
            val beforeMaghrib = fast.maghrib == 0L || now < fast.maghrib
            if (fast.today != null && beforeMaghrib) {
                val arafah = fast.today == "arafah"
                return when {
                    fast.done -> Messages(
                        listOf(
                            if (arafah) "Semangat puasa Arafah-nya! Bentar lagi buka 🌙 Jangan lupa banyak doa ya 🤲"
                            else "Semangat puasa Tarwiyah-nya! Besok lanjut Arafah ya 🌙",
                        ),
                        listOf("Semangat puasanya 🌙", "Bentar lagi buka ✨"),
                    )
                    arafah -> Messages(
                        listOf(
                            "Hari Arafah nih! Puasa hari ini hapus dosa setahun lalu & setahun depan. Worth it banget 🌙",
                            "Hari Arafah, momen terbaik buat doa. Puasa & minta apa aja yuk 🤲",
                            "Hari Arafah vibes 🌙 Puasa yuk, pahalanya auto double combo ✨",
                        ),
                        listOf("Hari Arafah, puasa yuk 🌙", "Puasa Arafah yuk ✨"),
                    )
                    else -> Messages(
                        listOf(
                            "Hari Tarwiyah nih, pemanasan sebelum Arafah. Puasa yuk 🌙",
                            "8 Dzulhijjah, hari terbaik buat beramal. Gas puasa Tarwiyah ✨",
                        ),
                        listOf("Hari Tarwiyah, puasa yuk 🌙", "Puasa Tarwiyah yuk ✨"),
                    )
                }
            }
            if (fast.tomorrow != null && !beforeMaghrib) {
                return if (fast.tomorrow == "arafah") Messages(
                    listOf(
                        "Besok Hari Arafah! Niat puasa & pasang alarm sahur ya ⏰",
                        "Besok Arafah 🌙 Jangan lupa sahur, ini puasa yang paling worth it.",
                    ),
                    listOf("Besok Arafah, sahur ya ⏰", "Besok puasa Arafah 🌙"),
                ) else Messages(
                    listOf(
                        "Besok Tarwiyah, lusa Arafah 🌙 Niat puasa & siapin sahur ya.",
                        "Besok puasa Tarwiyah yuk, pasang alarm sahur dari sekarang ⏰",
                    ),
                    listOf("Besok Tarwiyah, sahur ya ⏰", "Besok puasa Tarwiyah 🌙"),
                )
            }
            return null
        }

        /** Jam "HH:mm" untuk [at], mengikuti label jadwal bila ada. */
        private fun hm(at: Long, sholat: List<Prayer>, tomorrowSubuh: Prayer?): String {
            (sholat + listOfNotNull(tomorrowSubuh)).firstOrNull { it.at == at && it.time.isNotEmpty() }
                ?.let { return it.time }
            val cal = Calendar.getInstance().apply { timeInMillis = at }
            return "%02d:%02d".format(cal.get(Calendar.HOUR_OF_DAY), cal.get(Calendar.MINUTE))
        }

        /** Perkiraan jumlah baris [text] pada lebar [roomDp] ([sp], medium). */
        private fun lines(context: Context, text: String, roomDp: Float, sp: Float): Int {
            val metrics = context.resources.displayMetrics
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, sp, metrics)
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            }
            val width = paint.measureText(text) / metrics.density
            // cadangan ±20% untuk pemenggalan per kata
            return ceil(width * 1.2f / roomDp).toInt().coerceAtLeast(1)
        }

        /* ----------------------------- refresh ----------------------------- */

        private fun refreshIntent(context: Context): PendingIntent {
            val ids = AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, SemangatWidgetProvider::class.java))
            val intent = Intent(context, SemangatWidgetProvider::class.java)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            return PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /**
         * Refresh berikutnya: pergantian keadaan terdekat (20 mnt sebelum
         * adzan, adzan, batas awal waktu, akhir waktu), tiap 5 mnt selama
         * pesan memuat hitungan menit, selebihnya 30 mnt. Alarm tak-eksak.
         */
        private fun scheduleNextRefresh(context: Context, prefs: SharedPreferences, now: Long) {
            val loaded = load(prefs, now)
            var at = now + IDLE_REFRESH_MS
            if (loaded != null) {
                val onTimeMs = loaded.root.optInt("onTimeMinutes", 15) * MINUTE
                val all = prayers(loaded.today.optJSONArray("sholat")) +
                    prayers(loaded.tomorrow?.optJSONArray("sholat")).take(1)
                val edges = all.flatMap { listOf(it.at - SOON_MIN * MINUTE, it.at, it.at + onTimeMs, it.end) }
                edges.filter { it > now }.minOrNull()?.let { at = minOf(at, it + 1000) }
                val current = currentPrayer(all, now)
                val soon = all.any { it.at > now && it.at - now <= SOON_MIN * MINUTE }
                if ((current != null && !current.done) || soon) at = minOf(at, now + LIVE_REFRESH_MS)
            }
            at = at.coerceAtLeast(now + MINUTE)
            val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarm.setAndAllowWhileIdle(AlarmManager.RTC, at, refreshIntent(context))
        }
    }
}
