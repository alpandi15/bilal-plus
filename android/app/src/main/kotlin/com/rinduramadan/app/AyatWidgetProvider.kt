package com.rinduramadan.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/**
 * Widget Ayat Harian: satu ayat per hari, digambar besar dengan font mushaf
 * pilihan pengguna (penggambar bitmap yang sama dengan widget Hafalan), plus
 * terjemahan bila muat. Flutter menitipkan 7 hari ke depan (`ayat_json`),
 * jadi ayat berganti tiap tengah malam walau aplikasi tidak dibuka.
 * Ketuk = buka ayatnya di pembaca (`rinduramadan://ayat?s=..&a=..`).
 */
class AyatWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val options = appWidgetManager.getAppWidgetOptions(id)
            appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, options))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), HomeWidgetPlugin.getData(context))
    }

    companion object {
        /** Entri hari [now] di data; bila tak ada, yang paling dekat sebelumnya, lalu yang pertama. */
        internal fun todayEntry(root: JSONObject, now: Long = System.currentTimeMillis()): JSONObject? {
            val days = root.optJSONArray("days") ?: return null
            if (days.length() == 0) return null
            val cal = Calendar.getInstance(TimeZone.getTimeZone(root.optString("tzId", "Asia/Jakarta")))
                .apply { timeInMillis = now }
            val key = "%04d-%02d-%02d".format(
                cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
            )
            var fallback: JSONObject? = null
            for (i in 0 until days.length()) {
                val d = days.getJSONObject(i)
                val date = d.optString("date")
                if (date == key) return d
                if (date < key) fallback = d
            }
            return fallback ?: days.getJSONObject(0)
        }

        fun buildViews(context: Context, prefs: SharedPreferences, options: Bundle): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.ayat_widget_layout)
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 120

            val root = prefs.getString("ayat_json", null)?.let {
                try { JSONObject(it) } catch (_: Exception) { null }
            }
            val entry = root?.let { todayEntry(it) }
            if (root == null || entry == null) {
                views.setOnClickPendingIntent(
                    R.id.aw_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                views.setViewVisibility(R.id.aw_ayah, View.GONE)
                views.setViewVisibility(R.id.aw_empty, View.VISIBLE)
                views.setViewVisibility(R.id.aw_translation, View.GONE)
                views.setTextViewText(R.id.aw_ref, "—")
                return views
            }

            val surah = entry.optInt("surah")
            val n = entry.optInt("n")
            views.setOnClickPendingIntent(
                R.id.aw_root,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("rinduramadan://ayat?s=$surah&a=$n"),
                ),
            )
            views.setTextViewText(R.id.aw_kicker, "AYAT HARI INI · ${entry.optString("name").uppercase()}")
            views.setTextViewText(R.id.aw_ref, "$surah:$n")

            val density = context.resources.displayMetrics.density
            // padding 22, kepala 16, panel ayat (margin 8 + padding 12); terjemahan 3 baris ±44
            val fixed = 22 + 16 + 20
            val showTranslation = heightDp - fixed - 44 >= 56
            val ayahH = heightDp - fixed - (if (showTranslation) 44 else 0)
            val ayahW = widthDp - 28 - 12
            val bitmap = HafalanWidgetProvider.renderAyah(
                context,
                entry.optString("ar"),
                root.optString("font", "lpmq"),
                (ayahW * density).toInt().coerceAtLeast(60),
                (ayahH * density).toInt().coerceAtLeast(40),
                false,
            )
            views.setViewVisibility(R.id.aw_ayah, View.VISIBLE)
            views.setViewVisibility(R.id.aw_empty, View.GONE)
            views.setImageViewBitmap(R.id.aw_ayah, bitmap)
            views.setContentDescription(R.id.aw_ayah, "${entry.optString("name")} ayat $n")
            views.setViewVisibility(R.id.aw_translation, if (showTranslation) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.aw_translation, entry.optString("tr"))
            return views
        }
    }
}
