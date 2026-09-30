package com.rinduramadan.app

import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/** Enam waktu yang tampil di kartu, urut. Padanan `cardPrayers`. */
val PRAYER_KEYS = listOf("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")

val PRAYER_LABELS = mapOf(
    "fajr" to "Subuh",
    "sunrise" to "Terbit",
    "dhuhr" to "Dzuhur",
    "asr" to "Ashar",
    "maghrib" to "Maghrib",
    "isha" to "Isya",
)

/** Fase hari + gaya kartunya. Padanan `DayPhase` & `phaseStyle` di Flutter. */
enum class DayPhase(
    val atlasName: String,
    val bg: IntArray,
    val accent: Int,
    val night: Boolean,
) {
    DAWN("dawn", intArrayOf(0xFFFFF5EB.toInt(), 0xFFFFE8CF.toInt(), 0xFFFFDCBB.toInt()), 0xFFB45309.toInt(), false),
    MORNING("morning", intArrayOf(0xFFFFFDF7.toInt(), 0xFFFFF4E0.toInt(), 0xFFFFEACB.toInt()), 0xFFB45309.toInt(), false),
    NOON("noon", intArrayOf(0xFFF6FCFF.toInt(), 0xFFE9F5FF.toInt(), 0xFFDCECFB.toInt()), 0xFF0369A1.toInt(), false),
    DUSK("dusk", intArrayOf(0xFFFFF1E6.toInt(), 0xFFFFDEC6.toInt(), 0xFFFFCAA8.toInt()), 0xFFC2410C.toInt(), false),
    NIGHT("night", intArrayOf(0xFF16233D.toInt(), 0xFF1D2B4A.toInt(), 0xFF25325A.toInt()), 0xFFC7D2FE.toInt(), true),
}

class DaySchedule(
    val date: String,
    val times: Map<String, Long>,
    val labels: Map<String, String>,
    /** Tanggal hijriah hari ini, dan yang berlaku sesudah Maghrib (dihitung Flutter). */
    val hijri: String,
    val hijriAfterMaghrib: String,
    /** Suasana latar: "normal" / "ramadan" / "eid" / "adha" - siang & sesudah Maghrib. */
    val season: String = "normal",
    val seasonAfterMaghrib: String = "normal",
    /** Kembang api malam: dini hari (sebelum Subuh) & sesudah Maghrib. */
    val fireworks: Boolean = false,
    val fireworksAfterMaghrib: Boolean = false,
)

/** Data yang dititipkan Flutter (`home_widget_service_io.dart`, kunci `schedule_json`). */
class WidgetData(
    val location: String,
    val tz: String,
    val tzId: String,
    val days: List<DaySchedule>,
) {
    companion object {
        fun parse(json: String?): WidgetData? {
            if (json.isNullOrEmpty()) return null
            return try {
                val root = JSONObject(json)
                val arr = root.getJSONArray("days")
                val days = ArrayList<DaySchedule>(arr.length())
                for (i in 0 until arr.length()) {
                    val d = arr.getJSONObject(i)
                    val labels = d.getJSONObject("labels")
                    days.add(
                        DaySchedule(
                            date = d.getString("date"),
                            times = PRAYER_KEYS.associateWith { d.getLong(it) },
                            labels = PRAYER_KEYS.associateWith { labels.getString(it) },
                            hijri = d.optString("hijri", ""),
                            hijriAfterMaghrib = d.optString("hijriAfterMaghrib", ""),
                            season = d.optString("season", "normal"),
                            seasonAfterMaghrib = d.optString("seasonAfterMaghrib", "normal"),
                            fireworks = d.optBoolean("fireworks", false),
                            fireworksAfterMaghrib = d.optBoolean("fireworksAfterMaghrib", false),
                        ),
                    )
                }
                if (days.isEmpty()) null
                else WidgetData(
                    location = root.getString("location"),
                    tz = root.getString("tz"),
                    tzId = root.optString("tzId", "Asia/Jakarta"),
                    days = days,
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}

class NextPrayer(val key: String, val at: Long, val isTomorrow: Boolean)

/**
 * Keadaan kartu pada suatu saat - padanan gabungan `getNextPrayer`,
 * `getCurrentPrayer`, `getDayPhase`, dan `formatDateInZone` di Flutter.
 */
class WidgetState(val data: WidgetData, val now: Long) {
    val timeZone: TimeZone = TimeZone.getTimeZone(data.tzId)
    private val cal: Calendar = Calendar.getInstance(timeZone).apply { timeInMillis = now }

    val todayKey: String = "%04d-%02d-%02d".format(
        cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
    )

    /** Jadwal hari ini; kalau data sudah kedaluwarsa, hari terakhir yang ada. */
    val todayIndex: Int = data.days.indexOfFirst { it.date == todayKey }
        .let { if (it >= 0) it else data.days.indexOfLast { d -> d.date < todayKey }.coerceAtLeast(0) }
    val today: DaySchedule = data.days[todayIndex]
    val stale: Boolean = today.date != todayKey

    val hour: Int = cal.get(Calendar.HOUR_OF_DAY)
    val quiet: Boolean = hour >= 22 || hour < 4

    val next: NextPrayer = run {
        for (k in PRAYER_KEYS) {
            val t = today.times[k]!!
            if (t > now) return@run NextPrayer(k, t, false)
        }
        val tomorrow = data.days.getOrNull(todayIndex + 1)
        // tak ada jadwal besok (data sudah 7 hari tak diperbarui): taksir
        // Subuh besok dari Subuh hari ini + 24 jam, meleset 1-2 menit saja
        NextPrayer("fajr", tomorrow?.times?.get("fajr") ?: (today.times["fajr"]!! + ONE_DAY_MS), true)
    }

    val current: String = PRAYER_KEYS.lastOrNull { today.times[it]!! <= now } ?: "isha"

    val phase: DayPhase = when {
        now < today.times["fajr"]!! -> DayPhase.NIGHT
        now < today.times["sunrise"]!! -> DayPhase.DAWN
        now < today.times["dhuhr"]!! -> DayPhase.MORNING
        now < today.times["asr"]!! -> DayPhase.NOON
        now < today.times["maghrib"]!! -> DayPhase.DUSK
        else -> DayPhase.NIGHT
    }

    val isDaytime: Boolean = now >= today.times["sunrise"]!! && now <= today.times["maghrib"]!!

    /** Posisi matahari 0..1 di sepanjang busur (terbit -> terbenam). */
    val sunProgress: Double = run {
        val rise = today.times["sunrise"]!!
        val set = today.times["maghrib"]!!
        if (set <= rise || !isDaytime) 0.0 else (now - rise).toDouble() / (set - rise)
    }

    /** Hari hijriah berganti saat Maghrib - sama dengan kartu di aplikasi. */
    val hijriLabel: String = if (now < today.times["maghrib"]!!) today.hijri else today.hijriAfterMaghrib

    /** Suasana Ramadan/Idulfitri - ikut berganti saat Maghrib seperti tanggal hijriah. */
    val season: String = if (now < today.times["maghrib"]!!) today.season else today.seasonAfterMaghrib

    /** Malam takbiran/Idulfitri: kembang api (hanya dipakai saat fase malam). */
    val fireworks: Boolean = if (now < today.times["maghrib"]!!) today.fireworks else today.fireworksAfterMaghrib

    val dateLabel: String = "${HARI[cal.get(Calendar.DAY_OF_WEEK)]}, ${cal.get(Calendar.DAY_OF_MONTH)} ${BULAN[cal.get(Calendar.MONTH)]}"

    /** Tengah malam berikutnya di zona waktu lokasi (ganti label tanggal). */
    val nextMidnight: Long = (cal.clone() as Calendar).apply {
        add(Calendar.DAY_OF_MONTH, 1)
        set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    companion object {
        const val ONE_DAY_MS = 24L * 60 * 60 * 1000
        private val HARI = arrayOf("", "Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jum'at", "Sabtu")
        private val BULAN = arrayOf(
            "Januari", "Februari", "Maret", "April", "Mei", "Juni",
            "Juli", "Agustus", "September", "Oktober", "November", "Desember",
        )
    }
}
