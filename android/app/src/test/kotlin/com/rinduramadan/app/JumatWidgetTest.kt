package com.rinduramadan.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class JumatWidgetTest {
    private fun at(day: Int, h: Int, m: Int = 0): Long =
        Calendar.getInstance(TimeZone.getTimeZone("Asia/Jakarta")).apply {
            set(2026, Calendar.OCTOBER, day, h, m, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

    private fun state(jumat: Boolean, now: Long): WidgetState {
        val times = mapOf(
            "fajr" to at(30, 4, 53), "sunrise" to at(30, 6, 7), "dhuhr" to at(30, 12, 10),
            "asr" to at(30, 15, 30), "maghrib" to at(30, 18, 13), "isha" to at(30, 19, 23),
        )
        val day = DaySchedule(
            date = "2026-10-30",
            times = times,
            labels = PRAYER_KEYS.associateWith { "00:00" },
            hijri = "",
            hijriAfterMaghrib = "",
            jumat = jumat,
        )
        return WidgetState(WidgetData("Medan", "WIB", "Asia/Jakarta", listOf(day)), now)
    }

    @Test
    fun jumat_laki_laki_dzuhur_disebut_jumat() {
        val s = state(true, at(30, 9))
        assertEquals("Jumat", s.labelOf("dhuhr"))
        assertEquals("Subuh", s.labelOf("fajr"))
        assertEquals("Dzuhur", state(false, at(30, 9)).labelOf("dhuhr"))
    }

    @Test
    fun pengingat_ke_masjid_sampai_masuk_ashar() {
        assertTrue(state(true, at(30, 9)).jumatReminder)
        assertTrue(state(true, at(30, 14, 59)).jumatReminder)
        assertFalse(state(true, at(30, 15, 31)).jumatReminder)
        assertFalse(state(false, at(30, 9)).jumatReminder)
    }

    @Test
    fun nama_jumat_kembali_dzuhur_bila_waktunya_habis_belum_dikerjakan() {
        val end = at(30, 15, 30)
        assertEquals("Jumat", WidgetNames.sholat("Jumat", end, false, at(30, 13)))
        assertEquals("Dzuhur", WidgetNames.sholat("Jumat", end, false, at(30, 16)))
        // sudah dikerjakan sebagai Jumat: tetap Jumat
        assertEquals("Jumat", WidgetNames.sholat("Jumat", end, true, at(30, 16)))
        assertEquals("Ashar", WidgetNames.sholat("Ashar", end, false, at(30, 16)))
    }
}
