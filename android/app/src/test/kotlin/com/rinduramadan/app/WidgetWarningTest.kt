package com.rinduramadan.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetWarningTest {
    @Test
    fun ashar_punya_dalil_khusus_dan_umum() {
        val t = WidgetWarning.threats("Ashar")
        assertTrue(t.first().contains("HR. Bukhari 520"))
        assertEquals(1 + 3, t.size)
    }

    @Test
    fun dzuhur_dan_maghrib_hanya_dalil_umum() {
        assertEquals(3, WidgetWarning.threats("Dzuhur").size)
        assertEquals(3, WidgetWarning.threats("Maghrib").size)
    }

    @Test
    fun setiap_ancaman_berumber_dan_ringkas() {
        for (n in listOf("Subuh", "Dzuhur", "Ashar", "Maghrib", "Isya")) {
            for (t in WidgetWarning.threats(n)) {
                assertTrue(t, Regex("""\((HR|QS)\. """).containsMatchIn(t))
                assertTrue(t, t.length <= 70)
            }
            assertTrue(WidgetWarning.qadhaLong(n).all { "tanpa uzur" in it })
            assertTrue(WidgetWarning.missedLong(n).all { "terlewat" in it })
        }
    }

    @Test
    fun tanpa_ikon_hati() {
        val hearts = listOf("🤍", "❤", "💕", "💖", "🥰", "💗", "♥")
        val all = listOf("Subuh", "Ashar").flatMap {
            WidgetWarning.qadhaLong(it) + WidgetWarning.missedLong(it) +
                WidgetWarning.qadhaShort(it) + WidgetWarning.missedShort(it)
        }
        for (t in all) assertTrue(t, hearts.none { it in t })
    }
}
