package com.rinduramadan.app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.graphics.Color
import android.os.Bundle
import android.widget.FrameLayout
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Pratinjau widget layar utama (build debug saja): menyusun RemoteViews
 * yang persis sama dengan yang dikirim ke launcher, lalu menempelkannya di
 * Activity biasa. Ekstra intent: `w`/`h` ukuran widget (dp), `now` epoch ms
 * untuk meniru jam tertentu (mis. malam hari).
 */
class WidgetPreviewActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val density = resources.displayMetrics.density
        val w = intent.getIntExtra("w", 250)
        val h = intent.getIntExtra("h", 150)
        val now = intent.getLongExtra("now", System.currentTimeMillis())

        val options = Bundle().apply {
            putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, w)
            putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, h)
        }
        val prefs = HomeWidgetPlugin.getData(this)
        val views = PrayerWidgetProvider.buildPreview(this, prefs, options, now)

        val host = FrameLayout(this).apply { setBackgroundColor(Color.parseColor("#FFFAF3")) }
        val card = FrameLayout(this)
        host.addView(
            card,
            FrameLayout.LayoutParams((w * density).toInt(), (h * density).toInt()).apply {
                leftMargin = (20 * density).toInt(); topMargin = (60 * density).toInt()
            },
        )
        card.addView(views.apply(this, card))
        setContentView(host)
    }
}
