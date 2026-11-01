package com.rinduramadan.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HafalanCueTest {
    private val ayah = "اِنَّ مَعَ الْعُسْرِ يُسْرًا"

    @Test
    fun angkaArab() {
        assertEquals("٣", HafalanWidgetProvider.arabicDigits(3))
        assertEquals("١٢٠", HafalanWidgetProvider.arabicDigits(120))
    }

    @Test
    fun kataAwalSesuaiJumlah() {
        val one = HafalanWidgetProvider.cueLine(6, ayah, 1)
        assertEquals("(٦)", one.prefix)
        assertEquals("اِنَّ", one.words)
        assertTrue(one.more)
        assertEquals("اِنَّ مَعَ", HafalanWidgetProvider.cueLine(6, ayah, 2).words)
    }

    @Test
    fun jumlahKataDibatasiDanAyatPendekTidakDipotong() {
        assertEquals("اِنَّ مَعَ الْعُسْرِ", HafalanWidgetProvider.cueLine(1, ayah, 9).words)
        val short = HafalanWidgetProvider.cueLine(1, "قُلْ هُوَ", 3)
        assertEquals("قُلْ هُوَ", short.words)
        assertFalse(short.more)
    }

    @Test
    fun labelTombolIntip() {
        assertEquals("Intip", HafalanWidgetProvider.peekLabel(true, false, false))
        assertEquals("Tutup", HafalanWidgetProvider.peekLabel(true, true, false))
        assertEquals("Tutup", HafalanWidgetProvider.peekLabel(false, false, false))
        assertEquals("Lihat", HafalanWidgetProvider.peekLabel(false, false, true))
    }
}
