package com.rinduramadan.app

import com.rinduramadan.app.WidgetMotivation.Phase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class WidgetMotivationTest {
    private fun at(h: Int, m: Int = 0): Long = Calendar.getInstance().apply {
        set(2026, Calendar.OCTOBER, 1, h, m, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    // jadwal kira-kira Medan
    private val times = WidgetMotivation.Times(
        subuh = at(4, 58), sunrise = at(6, 11), dzuhur = at(12, 17),
        ashar = at(15, 28), maghrib = at(18, 20), isya = at(19, 29),
    )

    @Test
    fun fase_mengikuti_waktu_sholat() {
        val cases = mapOf(
            at(3, 0) to Phase.PRE_DAWN,
            at(5, 30) to Phase.MORNING,
            at(6, 20) to Phase.MORNING, // belum 15 menit setelah terbit
            at(8, 0) to Phase.DHUHA,
            at(13, 0) to Phase.MIDDAY,
            at(16, 0) to Phase.AFTERNOON,
            at(18, 45) to Phase.EVENING,
            at(21, 0) to Phase.NIGHT,
            at(23, 15) to Phase.LATE_NIGHT,
            at(1, 0) to Phase.LATE_NIGHT,
        )
        for ((now, phase) in cases) assertEquals(phase, WidgetMotivation.phase(now, times))
    }

    @Test
    fun dhuha_belum_mengajak_sudah_memuji() {
        val belum = WidgetMotivation.lines(at(8), times, WidgetMotivation.Status(false, null, false), 0)
        assertTrue(belum.long.all { "Dhuha" in it })
        val sudah = WidgetMotivation.lines(at(8), times, WidgetMotivation.Status(true, null, false), 0)
        assertTrue(sudah.long.none { "rakaat" in it || "yuk" in it })
    }

    @Test
    fun larut_malam_jangan_begadang() {
        val l = WidgetMotivation.lines(at(23, 30), times, WidgetMotivation.Status(null, null, true), 0)
        assertTrue(l.long.any { "begadang" in it.lowercase() || "tidur" in it.lowercase() })
    }

    @Test
    fun berganti_tiap_jam() {
        val s = WidgetMotivation.Status(null, null, false)
        val a = WidgetMotivation.lines(at(13), times, s, 0).long.first()
        val b = WidgetMotivation.lines(at(14), times, s, 0).long.first()
        assertTrue(a != b)
    }

    @Test
    fun tanpa_ikon_hati() {
        val hearts = listOf("🤍", "❤", "💕", "💖", "🥰", "😍", "💗", "💞", "😘", "♥", "💌", "🫶", "💛", "💚", "💙", "💜", "🧡")
        for (phase in Phase.values().indices) {
            for (h in 0..23) {
                for (st in listOf(
                    WidgetMotivation.Status(false, false, false),
                    WidgetMotivation.Status(true, true, true),
                )) {
                    val l = WidgetMotivation.lines(at(h, 30), times, st, phase)
                    for (text in l.long + l.short) {
                        assertFalse(text, hearts.any { it in text })
                    }
                }
            }
        }
    }
}
