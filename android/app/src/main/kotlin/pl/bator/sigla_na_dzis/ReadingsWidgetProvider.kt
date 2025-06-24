package pl.bator.sigla_na_dzis

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.text.Html
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ReadingsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        sp: SharedPreferences
    ) {
        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.readings_widget_layout)

            val sigla = sp.getString("sigla", "Brak danych") ?: "Brak danych"
            val last = sp.getString("last_update", "Ostatnia aktualizacja: --:--") ?: "Ostatnia aktualizacja: --:--"

            views.setTextViewText(R.id.widget_sigla, Html.fromHtml(sigla))
            views.setTextViewText(R.id.widget_update_time, last)

            val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("siglaWidget://refresh")
            )
            views.setOnClickPendingIntent(R.id.widget_root, refreshIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        val intent = Intent().apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
            addCategory(Intent.CATEGORY_DEFAULT)
            data = Uri.parse("siglaWidget://refresh")
        }
        context.sendBroadcast(intent)
    }
}
