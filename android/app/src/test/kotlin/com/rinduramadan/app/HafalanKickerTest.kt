package com.rinduramadan.app

import org.junit.Assert.assertEquals
import org.junit.Test

class HafalanKickerTest {
    @Test
    fun kickerHanyaMenyebutMurajaahBilaAda() {
        assertEquals("HAFALAN · AL-FALAQ", HafalanWidgetProvider.kicker("Al-Falaq", 0))
        assertEquals("HAFALAN · AL-FALAQ · 3 MURAJA'AH", HafalanWidgetProvider.kicker("Al-Falaq", 3))
    }
}
