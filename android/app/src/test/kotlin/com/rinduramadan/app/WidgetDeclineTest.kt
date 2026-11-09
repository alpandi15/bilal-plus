package com.rinduramadan.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetDeclineTest {
    @Test
    fun turun_bila_jauh_di_bawah_rata_rata() {
        assertTrue(WidgetDecline.isDown(0.5, 0.8))
        assertTrue(WidgetDecline.isDown(0.65, 0.8))
        assertFalse(WidgetDecline.isDown(0.7, 0.8))
        // tanpa pembanding / kebiasaan belum terbentuk
        assertFalse(WidgetDecline.isDown(0.0, null))
        assertFalse(WidgetDecline.isDown(0.0, Double.NaN))
        assertFalse(WidgetDecline.isDown(0.0, 0.2))
    }

    @Test
    fun nada_mengikuti_alasan() {
        assertTrue(WidgetDecline.lines("sakit", true).first.all { "sakit" in it.lowercase() || "syafa" in it.lowercase() })
        assertTrue(WidgetDecline.lines("safar", true).first.isNotEmpty())
        assertTrue(WidgetDecline.lines("futur", true).first.any { "rutin walau sedikit" in it })
        // tanpa catatan: sesekali diajak mencatat; sudah ada catatan: tidak
        assertTrue(WidgetDecline.lines(null, false).first.any { "Catat" in it })
        assertFalse(WidgetDecline.lines("lainnya", true).first.any { "Catat" in it })
        for (r in listOf("sakit", "safar", "sibuk", "lelah", "futur", "lainnya", null)) {
            val (long, short) = WidgetDecline.lines(r, false)
            assertTrue(long.isNotEmpty() && short.isNotEmpty())
            assertTrue(short.all { it.length <= 32 })
        }
    }
}
