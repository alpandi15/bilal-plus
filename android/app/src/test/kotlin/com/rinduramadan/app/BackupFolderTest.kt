package com.rinduramadan.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BackupFolderTest {
    @Test
    fun hanyaBerkasCadanganYangDikenali() {
        assertTrue(BackupFolder.isCopy("bilalplus-cadangan-20261101-1200.json"))
        assertFalse(BackupFolder.isCopy("catatan.json"))
        assertFalse(BackupFolder.isCopy("bilalplus-cadangan-20261101-1200.txt"))
        assertFalse(BackupFolder.isCopy("lain-bilalplus-cadangan-1.json"))
    }
}
