package pl.bator.sigla_na_dzis

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.text.Html
import android.widget.RemoteViews
import androidx.core.net.toUri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ReadingsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.readings_widget_layout)

            val sigla = widgetData.getString("sigla", "Brak danych") ?: "Brak danych"
            val last = widgetData.getString("last_update", "Ostatnia aktualizacja: --:--")
                ?: "Ostatnia aktualizacja: --:--"

            views.setTextViewText(R.id.widget_sigla, Html.fromHtml(sigla))
            views.setTextViewText(R.id.widget_update_time, last)

            val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                "siglaWidget://refresh".toUri()
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_icon, refreshIntent)

            val launchAppIntent =
                Intent(context, Class.forName("pl.bator.sigla_na_dzis.MainActivity")).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        val intent = Intent().apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
            addCategory(Intent.CATEGORY_DEFAULT)
            data = "siglaWidget://refresh".toUri()
        }
        context.sendBroadcast(intent)
    }

}

