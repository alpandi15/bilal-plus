package com.rinduramadan.app

import com.rinduramadan.app.SemangatWidgetProvider.Companion.Fast
import com.rinduramadan.app.SemangatWidgetProvider.Companion.Prayer
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class SemangatMessagesTest {
    private val hour = 60 * 60_000L
    private fun at(h: Int, m: Int = 0): Long = Calendar.getInstance().apply {
        set(2026, Calendar.OCTOBER, 26, h, m, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    private fun prayer(
        id: Int, name: String, start: Long, end: Long,
        done: Boolean = false, status: String? = null, prayedMs: Long = 0L,
    ) = Prayer(id, name, start, end, "", done, false, status, prayedMs)

    private val none = Fast(null, false, null, 0L)
    private val motivation = WidgetMotivation.Lines(listOf("motivasi"), listOf("m"))

    private fun day(
        dzuhur: Prayer, ashar: Prayer,
    ) = listOf(
        prayer(1, "Subuh", at(4, 58), at(6, 11), done = true, status = "onTime"),
        dzuhur,
        ashar,
        prayer(4, "Maghrib", at(18, 20), at(19, 29)),
        prayer(5, "Isya", at(19, 29), at(28, 58)),
    )

    private fun msg(sholat: List<Prayer>, now: Long) =
        SemangatWidgetProvider.messages(sholat, null, false, now, 15 * 60_000L, none, motivation)

    @Test
    fun terlewat_memuat_ancaman_berdalil() {
        // 21:00 - Dzuhur, Ashar & Maghrib terlewat; Isya sedang berjalan & sudah dicentang
        val s = day(
            prayer(2, "Dzuhur", at(12, 17), at(15, 28)),
            prayer(3, "Ashar", at(15, 28), at(18, 20)),
        ).toMutableList()
        s[4] = prayer(5, "Isya", at(19, 29), at(28, 58), done = true, status = "onTime", prayedMs = at(19, 40))
        val m = msg(s, at(22, 0))
        assertTrue(m.long.any { "HR." in it || "QS." in it })
        assertTrue(m.long.all { "terlewat" in it || "sholat" in it })
    }

    @Test
    fun qadha_tanpa_uzur_diancam_enam_jam() {
        val s = listOf(
            prayer(1, "Subuh", at(4, 58), at(6, 11), done = true, status = "qadha", prayedMs = at(7, 0)),
            prayer(2, "Dzuhur", at(12, 17), at(15, 28), done = true, status = "onTime", prayedMs = at(12, 20)),
            prayer(3, "Ashar", at(15, 28), at(18, 20), done = true, status = "onTime", prayedMs = at(15, 30)),
            prayer(4, "Maghrib", at(18, 20), at(19, 29), done = true, status = "onTime", prayedMs = at(18, 25)),
            prayer(5, "Isya", at(19, 29), at(28, 58), done = true, status = "onTime", prayedMs = at(19, 35)),
        )
        // 08:00 (1 jam sesudah dicatat): ancaman Subuh
        val soon = msg(s, at(8, 0))
        assertTrue(soon.long.any { "Bukhari 3030" in it })
        assertTrue(soon.long.all { "tanpa uzur" in it })
        // 14:00 (7 jam sesudah): ancaman sudah lewat, kembali motivasi
        val later = msg(s, at(14, 0))
        assertFalse(later.long.any { "tanpa uzur" in it })
    }

    @Test
    fun qadha_karena_uzur_tidak_diancam() {
        val s = listOf(
            prayer(1, "Subuh", at(4, 58), at(6, 11), done = true, status = "uzur", prayedMs = at(7, 0)),
            prayer(2, "Dzuhur", at(12, 17), at(15, 28), done = true, status = "onTime", prayedMs = at(12, 20)),
            prayer(3, "Ashar", at(15, 28), at(18, 20), done = true, status = "onTime", prayedMs = at(15, 30)),
            prayer(4, "Maghrib", at(18, 20), at(19, 29), done = true, status = "onTime", prayedMs = at(18, 25)),
            prayer(5, "Isya", at(19, 29), at(28, 58), done = true, status = "onTime", prayedMs = at(19, 35)),
        )
        val m = msg(s, at(8, 0))
        assertFalse(m.long.any { "HR." in it || "QS." in it })
    }
}
