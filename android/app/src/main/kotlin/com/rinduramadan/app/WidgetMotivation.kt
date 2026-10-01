package com.rinduramadan.app

import org.json.JSONArray
import java.util.Calendar

/**
 * Ucapan motivasi menurut waktu - dipakai widget Semangat Sholat & Ibadah
 * Harian saat tidak ada sholat yang mendesak (belum dikerjakan, sebentar
 * lagi, terlewat). Pagi: dzikir & semangat; Dhuha: ajakan sholat Dhuha;
 * siang & sore: ibadah ringan di sela aktivitas; malam: tidur awal; lewat
 * jam 23: jangan begadang; sepertiga malam: tahajud.
 *
 * Ikon sengaja umum (bukan hati/love) - pengguna bisa laki-laki maupun
 * perempuan.
 */
object WidgetMotivation {
    private const val MINUTE = 60_000L

    /** Waktu sholat hari ini (epoch ms); [sunrise] = akhir waktu Subuh. */
    class Times(
        val subuh: Long,
        val sunrise: Long,
        val dzuhur: Long,
        val ashar: Long,
        val maghrib: Long,
        val isya: Long,
    ) {
        val valid get() = subuh > 0 && sunrise > subuh && dzuhur > sunrise &&
            ashar > dzuhur && maghrib > ashar && isya > maghrib
    }

    /**
     * Keadaan ibadah hari ini: null = ibadah itu tidak aktif di checklist.
     * [allSholat] = lima waktu sudah semua.
     */
    class Status(val dhuha: Boolean?, val tilawah: Boolean?, val allSholat: Boolean)

    enum class Phase { LATE_NIGHT, PRE_DAWN, MORNING, DHUHA, MIDDAY, AFTERNOON, EVENING, NIGHT }

    /** Variasi pesan: [long] untuk ruang lega, [short] untuk widget sempit. */
    class Lines(val long: List<String>, val short: List<String>)

    fun phase(now: Long, t: Times): Phase {
        val hour = Calendar.getInstance().apply { timeInMillis = now }.get(Calendar.HOUR_OF_DAY)
        if (hour >= 23 || hour < 2) return Phase.LATE_NIGHT
        if (!t.valid) {
            return when (hour) {
                in 2..4 -> Phase.PRE_DAWN
                in 5..6 -> Phase.MORNING
                in 7..10 -> Phase.DHUHA
                in 11..14 -> Phase.MIDDAY
                in 15..17 -> Phase.AFTERNOON
                in 18..19 -> Phase.EVENING
                else -> Phase.NIGHT
            }
        }
        return when {
            now < t.subuh -> Phase.PRE_DAWN
            // waktu Dhuha mulai ±15 menit setelah matahari terbit
            now < t.sunrise + 15 * MINUTE -> Phase.MORNING
            now < t.dzuhur -> Phase.DHUHA
            now < t.ashar -> Phase.MIDDAY
            now < t.maghrib -> Phase.AFTERNOON
            now < t.isya -> Phase.EVENING
            else -> Phase.NIGHT
        }
    }

    /**
     * Pesan untuk [now], diputar per jam supaya berganti sepanjang fase
     * (widget diperbarui ±30 menit sekali).
     */
    fun lines(now: Long, t: Times, s: Status, seed: Int): Lines {
        val raw = raw(phase(now, t), s)
        val hour = Calendar.getInstance().apply { timeInMillis = now }.get(Calendar.HOUR_OF_DAY)
        return Lines(rotate(raw.long, seed + hour), rotate(raw.short, seed + hour))
    }

    private fun rotate(list: List<String>, by: Int): List<String> {
        if (list.isEmpty()) return list
        val start = Math.floorMod(by, list.size)
        return list.drop(start) + list.take(start)
    }

    private fun raw(phase: Phase, s: Status): Lines = when (phase) {
        Phase.LATE_NIGHT -> Lines(
            listOf(
                "Udah lewat jam 11 nih. Tidur yuk, biar Subuh nggak kelewat 😴",
                "Begadang bikin Subuh berat. Taruh HP-nya, istirahat sekarang ya 🌙",
                "Badan juga punya hak untuk istirahat. Tidur dulu, besok lanjut lagi 😴",
                "Scroll-nya udahan dulu ya. Pasang alarm Subuh, terus tidur 🌙",
                "Masih melek? Tidur sekarang, jangan sampai Subuh jadi korban begadang ⏰",
            ),
            listOf("Udah malam, tidur yuk 😴", "Jangan begadang ya 🌙", "Tidur, jaga Subuh ⏰"),
        )
        Phase.PRE_DAWN -> Lines(
            listOf(
                "Sepertiga malam terakhir: waktu doa paling mustajab. Tahajud dua rakaat yuk 🌙",
                "Allah turun ke langit dunia di akhir malam, siapa yang berdoa dikabulkan 🤲",
                "Kebangun? Wudhu, tahajud & witir sebentar, lalu tunggu Subuh 🌙",
                "Sunyi begini enak buat curhat ke Allah. Tahajud yuk 🤲",
            ),
            listOf("Tahajud yuk 🌙", "Waktu doa mustajab 🤲", "Witir dulu yuk 🌙"),
        )
        Phase.MORNING -> Lines(
            listOf(
                "Pagi! Awali dengan dzikir pagi biar hari ini terjaga 📿",
                "Bismillah, semoga hari ini penuh berkah & produktif 🌅",
                "Waktu pagi itu diberkahi. Mulai kerjaan penting sekarang 💪",
                "Udah dzikir pagi? 5 menit aja, bekal seharian 📿",
                "Semangat pagi! Niatkan semua aktivitas hari ini sebagai ibadah 🌅",
            ),
            listOf("Dzikir pagi yuk 📿", "Bismillah, semangat 🌅", "Pagi penuh berkah ✨"),
        )
        Phase.DHUHA -> if (s.dhuha == true) Lines(
            listOf(
                "Dhuha udah ✅ Masyaa Allah. Lanjut produktif, rezeki dijemput 💪",
                "Mantap, Dhuha beres! Sekarang fokus kerja & belajar, Allah yang cukupkan ✨",
                "Dhuha tertunai. Semoga hari ini lancar & penuh berkah 🌤️",
            ),
            listOf("Dhuha beres ✅", "Lanjut produktif 💪", "Semoga berkah ✨"),
        ) else Lines(
            listOf(
                "Waktu Dhuha nih ☀️ Dua rakaat Dhuha mencukupi sedekah seluruh persendianmu (HR. Muslim)",
                "Sela kerjaan sebentar, sholat Dhuha 2 rakaat yuk ☀️",
                "Dhuha: sholat para awwabin, yang suka kembali ke Allah. Gas sebelum siang ☀️",
                "Rezeki dijemput dengan usaha, dibuka dengan Dhuha. Yuk 2 rakaat dulu 🌤️",
                "Matahari udah naik, waktunya Dhuha. 5 menit aja kok ☀️",
            ),
            listOf("Dhuha yuk ☀️", "2 rakaat Dhuha 🌤️", "Waktunya Dhuha ☀️"),
        )
        Phase.MIDDAY -> Lines(
            listOf(
                "Siang-siang capek? Istirahat sebentar (qailulah) biar segar lagi 😌",
                "Di sela kerja, sholawat 10x yuk. Ringan tapi berat timbangannya ✨",
                "Satu halaman Al-Qur'an di jam istirahat? Bisa banget 📖",
                "Jaga lisan & hati di tengah sibuk, istighfar jalan terus 📿",
                "Kerja yang diniatkan ibadah = pahala sepanjang hari. Semangat 💪",
            ) + tilawahLong(s),
            listOf("Sholawat dulu ✨", "Istighfar jalan terus 📿", "Semangat siang 💪"),
        )
        Phase.AFTERNOON -> Lines(
            listOf(
                "Sore! Jangan lupa dzikir petang, pelindung sampai pagi 📿",
                "Jelang Maghrib, kurangi urusan dunia, perbanyak doa 🤲",
                "Capek seharian? Istighfar, insyaa Allah lapang lagi 🌇",
                "Sore yang tenang enak buat tilawah sebentar 📖",
                "Selesaikan kerjaan dengan baik, Allah suka yang itqan 💪",
            ) + tilawahLong(s),
            listOf("Dzikir petang yuk 📿", "Perbanyak doa 🤲", "Tilawah sore 📖"),
        )
        Phase.EVENING -> Lines(
            listOf(
                "Habis Maghrib waktu yang pas buat tilawah. Beberapa ayat juga cukup 📖",
                "Maghrib-Isya: kumpul keluarga, ngaji bareng, quality time 🌙",
                "Sambil nunggu Isya, dzikir & sholawat yuk 📿",
                "Malam mulai, matikan notifikasi sebentar, nikmati waktu ibadah 🌙",
            ) + tilawahLong(s),
            listOf("Tilawah habis Maghrib 📖", "Nunggu Isya, dzikir 📿", "Ngaji bareng yuk 🌙"),
        )
        Phase.NIGHT -> Lines(
            (if (s.allSholat) listOf(
                "Lima waktu beres hari ini 🔥 Tidur lebih awal ya, biar Subuh on time.",
                "Masyaa Allah, sholat hari ini lengkap. Tutup hari dengan istighfar & tidur awal 🌙",
            ) else emptyList()) + listOf(
                "Rasulullah tidak suka begadang setelah Isya. Tidur lebih awal yuk 🌙",
                "Sebelum tidur: wudhu, Ayat Kursi & tiga Qul. Tidur pun bernilai ibadah 😴",
                "Jangan lupa witir sebelum tidur kalau khawatir nggak bangun malam 🌙",
                "Baca Al-Mulk sebelum tidur yuk, penjaga dari azab kubur 📖",
                "Tidur awal = bangun Subuh lebih ringan. Pasang alarm dulu ⏰",
                "Muhasabah sebentar: hari ini udah ngapain aja? Istighfar, lalu tidur 🤲",
            ),
            listOf("Tidur awal yuk 😴", "Witir dulu 🌙", "Pasang alarm Subuh ⏰"),
        )
    }

    private fun tilawahLong(s: Status): List<String> = when (s.tilawah) {
        false -> listOf(
            "Tilawah hari ini belum tercatat. Satu halaman dulu yuk 📖",
            "Tiap huruf Al-Qur'an = 10 kebaikan (HR. Tirmidzi). Baca sebentar yuk 📖",
        )
        true -> listOf("Tilawah hari ini udah ✅ Barakallahu fik, istiqamah ya 📖")
        null -> emptyList()
    }

    /**
     * Keadaan Dhuha & tilawah dari daftar item widget ([items], kunci centang
     * tertunda "[date]|id" di [pending]).
     */
    fun status(items: JSONArray?, pending: Map<String, Int>, date: String, allSholat: Boolean): Status {
        var dhuha: Boolean? = null
        var tilawah: Boolean? = null
        if (items != null) {
            for (i in 0 until items.length()) {
                val o = items.getJSONObject(i)
                val id = o.optInt("id")
                val done = pending["$date|$id"]?.let { v ->
                    if (o.optString("kind") == "counter") v >= o.optInt("target", 1) else v > 0
                } ?: o.optBoolean("done", false)
                val name = o.optString("name").lowercase()
                if (name.contains("dhuha") || name.contains("duha")) dhuha = (dhuha ?: false) || done
                if (o.optString("kind") == "tilawah") tilawah = (tilawah ?: false) || done
            }
        }
        return Status(dhuha, tilawah, allSholat)
    }
}
