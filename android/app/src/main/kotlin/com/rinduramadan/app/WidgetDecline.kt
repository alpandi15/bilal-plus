package com.rinduramadan.app

/**
 * Widget Semangat Sholat di malam hari (sesudah adzan Isya) saat ibadah hari
 * ini turun dibanding rata-rata 7 hari sebelumnya (`recentRate` di
 * `ibadah_json`): kata penyemangat supaya besok lebih semangat lagi.
 *
 * Alasan dari catatan harian (`reason`: sakit, safar, sibuk, lelah, futur,
 * lainnya) memilih nadanya - yang sakit/safar didoakan & ditenangkan, yang
 * futur diajak mulai dari amalan kecil. Tanpa catatan, sesekali diajak
 * mencatat alasannya di aplikasi.
 */
internal object WidgetDecline {
    /** Turun bila hari ini kurang dari rata-rata dikurangi sekian (poin). */
    const val DROP = 0.15

    /** Rata-rata yang terlalu kecil tidak dibandingkan (belum ada kebiasaan). */
    const val MIN_RECENT = 0.3

    /** Hari ini ([today], 0..1) turun dari biasanya ([recent], 0..1)? */
    fun isDown(today: Double, recent: Double?): Boolean =
        recent != null && !recent.isNaN() && recent >= MIN_RECENT && today <= recent - DROP

    /** Variasi pesan panjang & singkat untuk [reason] (null = tanpa alasan). */
    fun lines(reason: String?, hasNote: Boolean): Pair<List<String>, List<String>> = when (reason) {
        "sakit" -> listOf(
            "Lagi sakit ya 🤍 Amalan rutinmu tetap ditulis pahalanya. Istirahat, semoga besok lebih segar.",
            "Ibadah hari ini lebih sedikit karena sakit, nggak apa-apa 🤍 Semoga lekas sembuh ya.",
            "Syafakallah 🤲 Yang wajib semampunya, sisanya istirahat. Besok pelan-pelan lagi.",
        ) to listOf("Semoga lekas sembuh 🤍", "Istirahat dulu ya 🤲")
        "safar" -> listOf(
            "Lagi di perjalanan ya 🧳 Pahala amalan rutinmu tetap ditulis. Besok balik ke ritme lagi ✨",
            "Safar bikin jadwal berantakan, wajar kok 🧳 Istirahat, besok semangat lagi ya.",
            "Hati-hati di jalan 🧳 Jamak & qashar itu keringanan, pakai aja. Besok gas lagi ✨",
        ) to listOf("Safar aman, besok lagi ✨", "Hati-hati di jalan 🧳")
        "sibuk" -> listOf(
            "Hari ini padat banget ya 💼 Besok sisihkan 10 menit di awal hari buat ibadah, pasti beda ✨",
            "Kerjaan menang dulu hari ini, besok giliran ibadah yang duluan 💪",
            "Sibuk boleh, tapi besok isi baterai ruhani dulu sebelum mulai kerja ya 🔋",
        ) to listOf("Besok ibadah duluan 💪", "Besok sisihkan 10 menit ✨")
        "lelah" -> listOf(
            "Capek itu manusiawi 😮‍💨 Tidur awal malam ini biar Subuh besok segar 🌙",
            "Hari ini lelah, ibadahnya ikut turun. Recharge dulu, besok gas lagi ✨",
            "Badan juga punya hak istirahat 🌙 Tidur awal, besok bangun lebih semangat.",
        ) to listOf("Tidur awal, besok segar 🌙", "Recharge dulu ya ✨")
        "futur" -> listOf(
            "Lagi futur itu wajar, yang penting jangan berhenti 🤍 Besok mulai dari satu amalan kecil aja.",
            "Amalan yang paling dicintai Allah: yang rutin walau sedikit. Besok pilih satu, jaga terus ✨",
            "Iman naik-turun itu normal 🌱 Istighfar malam ini, besok kita mulai lagi pelan-pelan.",
        ) to listOf("Besok mulai lagi pelan-pelan 🌱", "Satu amalan kecil besok ✨")
        else -> (
            listOf(
                "Hari ini ibadahnya agak turun dari biasanya. Nggak apa-apa, besok kita bangkit lagi 💪",
                "Hari ini kurang maksimal? Istighfar, tidur awal, besok lebih semangat lagi ya ✨",
                "Semua orang pernah drop. Yang penting besok coba lagi 🌱 Bismillah.",
                "Tutup hari dengan istighfar 🤲 Besok mulai lagi dari Subuh tepat waktu ✨",
            ) + if (hasNote) emptyList() else listOf(
                "Ibadah lagi turun? Catat sebabnya di Bilal+ biar kelihatan polanya 📝 Besok semangat lagi!",
            )
        ) to listOf("Besok lebih semangat lagi 💪", "Besok bangkit lagi ✨")
    }
}
