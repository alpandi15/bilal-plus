package com.rinduramadan.app

/**
 * Peringatan di widget untuk sholat yang diqadha tanpa uzur / terlewat:
 * ancaman dari dalil shahih (sama dengan lembar peringatan di aplikasi,
 * lib/data/sholat_dalil.dart) - singkat, lengkap dengan rujukannya. Qadha
 * karena uzur (tertidur, lupa, ...) TIDAK diberi ancaman - tidak berdosa.
 */
object WidgetWarning {
    /** Dalil yang berlaku untuk semua sholat. */
    private val general = listOf(
        "Meninggalkan sholat = batas dengan kekufuran (HR. Muslim 116)",
        "Mengabaikan sholat, kelak tersesat (QS. Maryam: 59)",
        "Celakalah yang lalai dari sholatnya (QS. Al-Ma'un: 4-5)",
    )

    /** Dalil khusus per sholat (kunci: nama huruf kecil); Dzuhur & Maghrib tidak ada. */
    private fun specific(name: String): String? = when (name.lowercase()) {
        "subuh" -> "Tidur lewat Subuh: dikencingi setan (HR. Bukhari 3030)"
        "ashar" -> "Meninggalkan Ashar, hapuslah amalnya (HR. Bukhari 520)"
        "isya" -> "Isya & Subuh paling berat bagi munafik (HR. Bukhari 617)"
        else -> null
    }

    /** Ancaman singkat (≤ ±60 huruf) untuk sholat [name]: khusus dulu, lalu umum. */
    fun threats(name: String): List<String> = listOfNotNull(specific(name)) + general

    /** Qadha tanpa uzur untuk widget lega (beberapa baris). */
    fun qadhaLong(name: String): List<String> =
        threats(name).map { "$name diqadha tanpa uzur. $it. Segera istighfar ⚠️" }

    /** Sholat belum dikerjakan & waktunya habis. */
    fun missedLong(name: String): List<String> =
        threats(name).map { "$name terlewat! $it. Qadha sekarang & bertaubat ⚠️" }

    fun qadhaShort(name: String): List<String> = listOf(
        "Qadha tanpa uzur = lalai ⚠️",
        "$name tanpa uzur, taubat ya ⚠️",
    )

    fun missedShort(name: String): List<String> = listOf(
        "$name terlewat, dosa besar ⚠️",
        "Segera qadha & taubat ⚠️",
    )
}

/**
 * Nama sholat di widget. Hari Jumat (laki-laki) Dzuhur bernama "Jumat" (lihat
 * `jumatAware` di ibadah_day.dart); Jumat yang waktunya habis & belum
 * dikerjakan tidak bisa diqadha - sisanya Dzuhur 4 rakaat, jadi kembali
 * disebut "Dzuhur".
 */
object WidgetNames {
    fun sholat(name: String, end: Long, done: Boolean, now: Long = System.currentTimeMillis()): String =
        if (name == "Jumat" && end in 1 until now && !done) "Dzuhur" else name
}
