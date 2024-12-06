package es.antonborri.home_widget_counter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import android.util.TypedValue
import android.util.Log
import android.os.Bundle
import android.widget.Toast


class QuoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {

        appWidgetIds.forEach { widgetId ->
//            val layoutId = if (widgetData.getString("flutter.size", "small") == "small") {
//                R.layout.quote_widget_small
//            } else {
//                R.layout.quote_widget_large
//            }

            val views = RemoteViews(context.packageName, R.layout.quote_widget).apply {
                // Retrieve the saved quote from SharedPreferences
                val quote =
                    widgetData.getString("quote", "Fetching quote...") ?: "Fetching quote..."
                setTextViewText(R.id.text_quotes, quote)
                // val fontSize: Float = widgetData.getFloat("flutter.fontSize", 20.0f)
                Log.d("tdg", "Came here");
                val fontSize: String = widgetData.getString("flutter.fontSize", "25").toString()
                val floatValue: Float = fontSize.toFloat()
                setTextViewTextSize(R.id.text_quotes, TypedValue.COMPLEX_UNIT_SP, floatValue);


                // Create an intent for fetching a new quote
                val fetchQuoteIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("homeWidgetQuote://fetchQuote")
                )

                // Set onClick to fetch a new quote
                setOnClickPendingIntent(R.id.button_next, fetchQuoteIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
    override fun onEnabled(context: Context) {
        // Handle widget creation event here, if needed
        // You can initialize shared preferences here if you want to provide default values
        super.onEnabled(context)

        // Example: When a widget is enabled, set default preferences for font size
        val appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID // Ensure proper handling for the widget ID
        val prefs = context.getSharedPreferences("widget_prefs_$appWidgetId", Context.MODE_PRIVATE)
        val editor = prefs.edit()

        // Set default font size for the new widget
        editor.putInt("fontSize", 24)  // Default font size
        editor.apply()

        // Optionally show a Toast for debugging
        Toast.makeText(context, "Widget enabled. Default font size applied.", Toast.LENGTH_SHORT).show()
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)

        // Handle font size update for the widget when the user configures it.
        val prefs = context.getSharedPreferences("widget_prefs_$appWidgetId", Context.MODE_PRIVATE)
        val editor = prefs.edit()

        // Set font size based on user input (For instance, from settings)
        val newFontSize = 30 // Example: Font size from settings or user input
        editor.putInt("fontSize", newFontSize)
        editor.apply()

        // Optionally show a Toast for debugging
        Toast.makeText(context, "Font size updated to: $newFontSize", Toast.LENGTH_SHORT).show()
    }
}