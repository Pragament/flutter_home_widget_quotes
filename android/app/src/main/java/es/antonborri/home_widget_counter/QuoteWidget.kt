package es.antonborri.home_widget_counter

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.FontStyle
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.CountDownLatch

class QuoteWidget: FlutterActivity() {
}


//object SettingsHelper {
//    private const val PREFS_NAME = "quote_prefs"
//    private const val API_QUOTES_KEY = "apiQuotesEnabled"
//
//    fun isApiQuotesEnabled(context: Context): Boolean {
//        val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
//        return sharedPreferences.getBoolean(API_QUOTES_KEY, true) // Default to true
//    }
//
//    fun setApiQuotesEnabled(context: Context, isEnabled: Boolean) {
//        val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
//        sharedPreferences.edit().putBoolean(API_QUOTES_KEY, isEnabled).apply()
//    }
//}

object SettingsHelper {
    private const val PREFS_NAME = "FlutterSharedPreferences" // Match Flutter's default name
    private const val API_QUOTES_KEY = "flutter.apiQuotesEnabled" // Prefix with 'flutter.'

    fun isApiQuotesEnabled(context: Context): Boolean {
        val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return sharedPreferences.getBoolean(API_QUOTES_KEY, true) // Default to true
    }

    fun setApiQuotesEnabled(context: Context, isEnabled: Boolean) {
        val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sharedPreferences.edit().putBoolean(API_QUOTES_KEY, isEnabled).apply()
    }
}

