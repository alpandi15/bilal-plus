package com.rinduramadan.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/**
 * Widget Ibadah Harian: kemajuan hari ini, lima waktu yang bisa dicentang
 * langsung, dan ibadah lainnya - padanan ringkas halaman Ibadah Harian.
 *
 * Datanya (`ibadah_json`) disusun Flutter (`tracker_widget_payload.dart`):
 * hari ini DAN besok, supaya lewat tengah malam checklist baru langsung
 * tampil walau aplikasi belum dibuka.
 *
 * Mencentang dari widget:
 * 1. ketukan dikirim ke provider ini ([ACTION_SET]) - perubahannya langsung
 *    disimpan sebagai "tertunda" & widget digambar ulang (terasa instan),
 * 2. lalu diteruskan ke callback Dart di latar (`trackerWidgetCallback`,
 *    lewat home_widget) yang menulis ke basis data dan memperbarui
 *    `ibadah_json`,
 * 3. catatan tertunda dibuang begitu `ibadah_json` yang lebih baru tiba.
 */
class IbadahWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        appWidgetIds.forEach { id ->
            val options = appWidgetManager.getAppWidgetOptions(id)
            appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, options, now))
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

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_SET) {
            val uri = intent.data ?: return
            val date = uri.getQueryParameter("date") ?: return
            val item = uri.getQueryParameter("item")?.toIntOrNull() ?: return
            val value = uri.getQueryParameter("value")?.toIntOrNull() ?: return
            setPending(context, date, item, value)
            refreshAll(context)
            // tulis ke basis data lewat Dart di latar
            HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
            return
        }
        super.onReceive(context, intent)
    }

    companion object {
        const val ACTION_SET = "com.rinduramadan.app.IBADAH_SET"
        private const val PENDING_PREFS = "tracker_widget_pending"
        private const val PENDING_KEY = "ibadah"
        private const val MAX_ROWS = 7

        private val SHOLAT_IDS = listOf(
            Triple(R.id.ib_sholat_0, R.id.ib_sholat_dot_0, R.id.ib_sholat_name_0),
            Triple(R.id.ib_sholat_1, R.id.ib_sholat_dot_1, R.id.ib_sholat_name_1),
            Triple(R.id.ib_sholat_2, R.id.ib_sholat_dot_2, R.id.ib_sholat_name_2),
            Triple(R.id.ib_sholat_3, R.id.ib_sholat_dot_3, R.id.ib_sholat_name_3),
            Triple(R.id.ib_sholat_4, R.id.ib_sholat_dot_4, R.id.ib_sholat_name_4),
        )
        private val ROW_IDS = listOf(
            intArrayOf(R.id.ib_row_0, R.id.ib_row_name_0, R.id.ib_row_meta_0, R.id.ib_row_check_0),
            intArrayOf(R.id.ib_row_1, R.id.ib_row_name_1, R.id.ib_row_meta_1, R.id.ib_row_check_1),
            intArrayOf(R.id.ib_row_2, R.id.ib_row_name_2, R.id.ib_row_meta_2, R.id.ib_row_check_2),
            intArrayOf(R.id.ib_row_3, R.id.ib_row_name_3, R.id.ib_row_meta_3, R.id.ib_row_check_3),
            intArrayOf(R.id.ib_row_4, R.id.ib_row_name_4, R.id.ib_row_meta_4, R.id.ib_row_check_4),
            intArrayOf(R.id.ib_row_5, R.id.ib_row_name_5, R.id.ib_row_meta_5, R.id.ib_row_check_5),
            intArrayOf(R.id.ib_row_6, R.id.ib_row_name_6, R.id.ib_row_meta_6, R.id.ib_row_check_6),
        )

        private class Entry(
            val id: Int,
            val name: String,
            val kind: String,
            var value: Int,
            val target: Int,
            var done: Boolean,
            val excused: Boolean,
            val at: Long,
            val time: String,
            /** onTime / late / qadha - hanya bila pencatatan waktu sholat aktif. */
            var status: String?,
            val prayed: String,
        )

        private fun entries(arr: JSONArray?): MutableList<Entry> {
            if (arr == null) return mutableListOf()
            return (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                Entry(
                    id = o.getInt("id"),
                    name = o.getString("name"),
                    kind = o.optString("kind", "check"),
                    value = o.optInt("value", 0),
                    target = o.optInt("target", 1),
                    done = o.optBoolean("done", false),
                    excused = o.optBoolean("excused", false),
                    at = o.optLong("at", 0L),
                    time = o.optString("time", ""),
                    status = o.optString("status", "").ifEmpty { null },
                    prayed = o.optString("prayed", ""),
                )
            }.toMutableList()
        }

        /* ------------------------- catatan tertunda ------------------------- */

        private fun pendingPrefs(context: Context) =
            context.getSharedPreferences(PENDING_PREFS, Context.MODE_PRIVATE)

        private fun setPending(context: Context, date: String, item: Int, value: Int) {
            val prefs = pendingPrefs(context)
            val all = JSONObject(prefs.getString(PENDING_KEY, "{}") ?: "{}")
            all.put("$date|$item", JSONObject().put("v", value).put("t", System.currentTimeMillis()))
            prefs.edit().putString(PENDING_KEY, all.toString()).apply()
        }

        /** Catatan tertunda yang belum tercermin di `ibadah_json` ([generatedAt]). */
        private fun pending(context: Context, generatedAt: Long): Map<String, Int> {
            val prefs = pendingPrefs(context)
            val all = JSONObject(prefs.getString(PENDING_KEY, "{}") ?: "{}")
            val live = JSONObject()
            val result = mutableMapOf<String, Int>()
            all.keys().forEach { k ->
                val o = all.getJSONObject(k)
                if (o.getLong("t") > generatedAt) {
                    live.put(k, o)
                    result[k] = o.getInt("v")
                }
            }
            if (live.length() != all.length()) {
                prefs.edit().putString(PENDING_KEY, live.toString()).apply()
            }
            return result
        }

        private fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, IbadahWidgetProvider::class.java))
            val prefs = HomeWidgetPlugin.getData(context)
            val now = System.currentTimeMillis()
            ids.forEach { id ->
                manager.updateAppWidget(id, buildViews(context, prefs, manager.getAppWidgetOptions(id), now))
            }
        }

        /* ------------------------------ intent ------------------------------ */

        private fun setIntent(context: Context, date: String, item: Int, value: Int): PendingIntent {
            val uri = Uri.parse("rinduramadan://ibadah/set?date=$date&item=$item&value=$value")
            val intent = Intent(context, IbadahWidgetProvider::class.java).apply {
                action = ACTION_SET
                data = uri
            }
            return PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun openApp(context: Context, page: String): PendingIntent =
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("rinduramadan://$page"),
            )

        /* ------------------------------ gambar ------------------------------ */

        fun buildViews(context: Context, prefs: SharedPreferences, options: Bundle, now: Long): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.ibadah_widget_layout)
            views.setOnClickPendingIntent(R.id.ib_root, openApp(context, "ibadah"))
            views.setOnClickPendingIntent(R.id.ib_more, openApp(context, "ibadah"))

            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 220

            val root = prefs.getString("ibadah_json", null)?.let {
                try { JSONObject(it) } catch (_: Exception) { null }
            }
            if (root == null) {
                empty(views, "Buka aplikasi untuk memulai")
                return views
            }

            val cal = Calendar.getInstance(TimeZone.getTimeZone(root.optString("tzId", "Asia/Jakarta")))
                .apply { timeInMillis = now }
            val today = "%04d-%02d-%02d".format(
                cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
            )
            val days = root.getJSONArray("days")
            val day = (0 until days.length()).map { days.getJSONObject(it) }
                .firstOrNull { it.getString("date") == today }
            if (day == null) {
                empty(views, "Buka aplikasi untuk memperbarui")
                return views
            }

            // terapkan centang yang belum dikonfirmasi basis data
            val pending = pending(context, root.optLong("generatedAt", 0L))
            val sholat = entries(day.optJSONArray("sholat"))
            val items = entries(day.optJSONArray("items"))
            var done = day.optInt("done", 0)
            for (e in sholat + items) {
                val v = pending["$today|${e.id}"] ?: continue
                val nowDone = if (e.kind == "counter") v >= e.target else v > 0
                if (!e.excused && nowDone != e.done) done += if (nowDone) 1 else -1
                e.value = v
                e.done = nowDone
                // status baru diketahui sesudah Dart mencatat jamnya
                if (!nowDone) e.status = null
            }
            val total = day.optInt("total", 0)
            val excused = day.optBoolean("excused", false)

            // kepala & kemajuan
            views.setTextViewText(R.id.ib_kicker, day.optString("kicker", "IBADAH HARIAN"))
            views.setTextViewText(R.id.ib_count, "$done/$total")
            views.setProgressBar(R.id.ib_progress, 1000, if (total == 0) 0 else done * 1000 / total, false)
            val streak = day.optInt("streak", 0)
            views.setTextViewText(
                R.id.ib_streak,
                when {
                    excused -> "Sedang berhalangan · streak tetap terjaga"
                    total > 0 && done >= total -> "Masyaa Allah, semua tuntas"
                    streak > 0 -> "🔥 $streak hari terjaga"
                    else -> day.optString("hijri", "")
                },
            )
            views.setViewVisibility(R.id.ib_streak, if (heightDp < 200) View.GONE else View.VISIBLE)

            // lima waktu: waktu yang sedang berjalan disorot
            val currentId = sholat.lastOrNull { it.at in 1..now }?.id
            SHOLAT_IDS.forEachIndexed { i, (col, dot, name) ->
                val e = sholat.getOrNull(i)
                if (e == null) {
                    views.setViewVisibility(col, View.GONE)
                    return@forEachIndexed
                }
                views.setViewVisibility(col, View.VISIBLE)
                views.setTextViewText(name, e.name)
                views.setImageViewResource(
                    dot,
                    when {
                        e.excused -> R.drawable.tracker_dot_off
                        e.done && e.status == "qadha" -> R.drawable.tracker_dot_qadha
                        e.done && e.status == "late" -> R.drawable.tracker_dot_late
                        e.done -> R.drawable.tracker_dot_done
                        e.id == currentId -> R.drawable.tracker_dot_now
                        else -> R.drawable.tracker_dot_todo
                    },
                )
                val statusLabel = when (e.status) {
                    "onTime" -> ", awal waktu"
                    "late" -> ", terlambat"
                    "qadha" -> ", qadha"
                    else -> ""
                }
                views.setContentDescription(
                    dot,
                    "${e.name} ${e.time}" + (if (e.done) ", sudah" else "") + statusLabel,
                )
                // jam sholat yang dicatat menggantikan nama saat sudah dikerjakan
                views.setTextViewText(name, if (e.done && e.prayed.isNotEmpty()) e.prayed else e.name)
                if (!e.excused) {
                    views.setOnClickPendingIntent(col, setIntent(context, today, e.id, if (e.done) 0 else 1))
                }
            }

            // ibadah lainnya: yang belum selesai di atas, sebanyak yang muat
            val used = 119 + (if (heightDp < 200) 0 else 14)
            val capacity = ((heightDp - used) / 30).coerceIn(0, MAX_ROWS)
            val ordered = items.sortedBy { if (it.done || it.excused) 1 else 0 }
            ROW_IDS.forEachIndexed { i, ids ->
                val (row, name, meta, check) = ids.toList()
                val e = ordered.getOrNull(i)
                if (e == null || i >= capacity) {
                    views.setViewVisibility(row, View.GONE)
                    return@forEachIndexed
                }
                views.setViewVisibility(row, View.VISIBLE)
                views.setTextViewText(name, e.name)
                views.setTextColor(name, if (e.excused) 0x80F7F1E1.toInt() else 0xFFF7F1E1.toInt())
                if (e.kind == "counter") {
                    views.setViewVisibility(meta, View.VISIBLE)
                    views.setTextViewText(meta, "${e.value}/${e.target}")
                    views.setViewVisibility(check, if (e.done) View.VISIBLE else View.GONE)
                } else {
                    views.setViewVisibility(meta, View.GONE)
                    views.setViewVisibility(check, View.VISIBLE)
                }
                views.setImageViewResource(
                    check,
                    when {
                        e.excused -> R.drawable.tracker_dot_off
                        e.done -> R.drawable.tracker_dot_done
                        else -> R.drawable.tracker_dot_todo
                    },
                )
                views.setOnClickPendingIntent(
                    row,
                    when {
                        // hitungan diisi di aplikasi; tilawah tercentang lewat catatan bacaan
                        e.excused || e.kind == "counter" -> openApp(context, "ibadah")
                        e.kind == "tilawah" -> openApp(context, "quran")
                        else -> setIntent(context, today, e.id, if (e.done) 0 else 1)
                    },
                )
            }

            val hidden = (ordered.size - capacity).coerceAtLeast(0)
            views.setTextViewText(
                R.id.ib_more,
                if (hidden > 0) "+$hidden lainnya ›" else "Buka checklist ›",
            )
            return views
        }

        private fun empty(views: RemoteViews, message: String) {
            views.setTextViewText(R.id.ib_kicker, "IBADAH HARIAN")
            views.setTextViewText(R.id.ib_count, "")
            views.setProgressBar(R.id.ib_progress, 1000, 0, false)
            views.setTextViewText(R.id.ib_streak, message)
            views.setViewVisibility(R.id.ib_streak, View.VISIBLE)
            views.setViewVisibility(R.id.ib_sholat_row, View.GONE)
            ROW_IDS.forEach { views.setViewVisibility(it[0], View.GONE) }
            views.setTextViewText(R.id.ib_more, "Buka aplikasi ›")
        }
    }
}
