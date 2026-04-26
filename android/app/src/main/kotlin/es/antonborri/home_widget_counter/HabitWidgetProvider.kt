package es.antonborri.home_widget_counter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HabitWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.habit_widget).apply {
                val title =
                    widgetData.getString("habit_widget_title", "No pending habits")
                        ?: "No pending habits"
                val time = widgetData.getString("habit_widget_time", "") ?: ""

                setTextViewText(R.id.habit_title, title)
                setTextViewText(R.id.habit_time, time)
                setViewVisibility(
                    R.id.habit_time,
                    if (time.isBlank()) View.GONE else View.VISIBLE
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
