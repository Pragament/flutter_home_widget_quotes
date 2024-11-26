package es.antonborri.home_widget_counter

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.ActionParameters
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.FontStyle
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import androidx.work.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.actionStartActivity
import android.content.SharedPreferences
import androidx.preference.PreferenceManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.runBlocking
import java.util.concurrent.CountDownLatch

class QuoteGlanceWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()
    private var glanceId: GlanceId? = null
    private var isPeriodicUpdateStarted = false  // Flag to track if handler has started

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        glanceId = id
        if (!isPeriodicUpdateStarted) {
            // Introduce a slight delay to ensure widget initialization
            Handler(Looper.getMainLooper()).postDelayed({
                startPeriodicUpdate(context)
                isPeriodicUpdateStarted = true
            }, 5000)  // 5 second delay
        }
        provideContent {
            GlanceContent(context, currentState())
        }
    }

    private fun startPeriodicUpdate(context: Context) {
        val handler = Handler(Looper.getMainLooper())
        val runnable = object : Runnable {
            override fun run() {
                CoroutineScope(Dispatchers.IO).launch {
                    val newQuote = fetchQuoteBasedOnPreference(context)

                    val prefs =
                        context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putString("quote", newQuote).apply()

                    // Update widget only if glanceId is still valid
                    glanceId?.let { validId ->
                        QuoteGlanceWidget().update(context, validId)
                    }
                }

                handler.postDelayed(this, 1*60*1000)  // Update every 1 minute
            }
        }

        handler.post(runnable)
    }

    private suspend fun fetchQuoteBasedOnPreference(context: Context): String {
        return withContext(Dispatchers.IO) {
            val isApiEnabled = SettingsHelper.isApiQuotesEnabled(context)
//            Log.d("Message", "The Api values is : ${isApiEnabled}")
            return@withContext if (isApiEnabled) {
//                fetchQuoteFromFlutter(context)
                fetchQuoteFromAPI()
            } else {
                fetchQuoteFromFlutter(context)
            }
        }
    }

    private fun fetchQuoteFromAPI(): String {
        return try {
            val url = URL("https://staticapis.pragament.com/daily/quotes-en-gratitude.json")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connect()

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val quotesArray = JSONObject(response).getJSONArray("quotes")
                val randomIndex = (0 until quotesArray.length()).random()
                val quoteObject = quotesArray.getJSONObject(randomIndex)
                quoteObject.getString("quote")
            } else {
                "Error fetching quote from API."
            }
        } catch (e: Exception) {
            "Error fetching quote from API."
        }
    }

    private fun fetchQuoteFromFlutter(context: Context): String {
        var quote = "Error fetching quote"
        val handler = Handler(Looper.getMainLooper())

        val latch = CountDownLatch(1) // To synchronize the main thread call
        handler.post {
            try {
                val flutterEngine = FlutterEngine(context).apply {
                    dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
                }
                val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "quote_channel")
//                Log.d("fetchQuoteFromFlutter", "MethodChannel initialized")

                methodChannel.invokeMethod("getQuoteFromHive", null, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        quote = result as? String ?: "No quotes found."
                        Log.d("fetchQuoteFromFlutter", "Fetched quote: $quote")
                        latch.countDown() // Signal completion
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        quote = "Error: $errorMessage"
                        latch.countDown() // Signal completion
                    }

                    override fun notImplemented() {
                        quote = "Method not implemented"
                        latch.countDown() // Signal completion
                    }
                })
            } catch (e: Exception) {
                Log.e("fetchQuoteFromFlutter", "Error fetching quote: ${e.message}")
                latch.countDown() // Signal completion
            }
        }

        latch.await() // Wait for the main thread to finish processing
        return quote
    }


//    private fun fetchAutoQuote(): String {
//        return try {
//            val url = URL("https://staticapis.pragament.com/daily/quotes-en-gratitude.json")
//            val connection = url.openConnection() as HttpURLConnection
//            connection.requestMethod = "GET"
//            connection.connect()
//
//            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
//                val response = connection.inputStream.bufferedReader().use { it.readText() }
//                val quotesArray = JSONObject(response).getJSONArray("quotes")
//                val randomIndex = (0 until quotesArray.length()).random()
//                val quoteObject = quotesArray.getJSONObject(randomIndex)
//                quoteObject.getString("quote")
//            } else {
//                "Error fetching quote"
//            }
//        } catch (e: Exception) {
//            "Error fetching quote"
//        }
//    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
        val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
        val prefs1 = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val quote = prefs.getString("quote", "Welcome to Gratitude Quotes")
        val fontSize: String = prefs1.getString("flutter.fontSize", "25").toString()
        Log.d("font", fontSize);
        if (!prefs.contains("fontSize_$glanceId")){
            prefs.edit().putString("fontSize_$glanceId", fontSize).apply()
        }
        val fontSize1: String = prefs.getString("fontSize_$glanceId", "25").toString()
        val floatValue: Float = fontSize1.toFloat()
       // val myString: String = fontSize.toString()
        Log.d("font1", fontSize1);
        Log.d("key", "fontSize_$glanceId");
//        val myString1: String =prefs1.getString("flutter.size", "small").toString()
//        Log.d("abc",myString1)

        Box(
            modifier = GlanceModifier
                .background(Color.White)
                .padding(8.dp)  // Reduced padding for a more compact layout
                .clickable(onClick = actionStartActivity<MainActivity>(context))
        ) {
            Column(
                verticalAlignment = Alignment.Vertical.Top,
                horizontalAlignment = Alignment.Horizontal.CenterHorizontally
            ) {
                Spacer(GlanceModifier.size(10.dp))
                Text(
                    text = quote ?: "Loading...",
                    style = TextStyle(fontSize = floatValue.sp,textAlign = TextAlign.Center, fontStyle = FontStyle.Italic),
                )
                Spacer(GlanceModifier.size(15.dp))
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.End
                ) {
                    Box(
                        modifier = GlanceModifier.clickable(onClick = actionRunCallback<FetchQuoteAction>())
                    ) {
                        Image(
                            provider = ImageProvider(R.drawable.baseline_add_24),
                            contentDescription = "Refresh",
                            colorFilter = ColorFilter.tint(ColorProvider(Color.Black)),
                            modifier = GlanceModifier.size(24.dp)  // Smaller image for minimal widget
                        )
                    }
                }
            }
        }
    }

}


class FetchQuoteAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val newQuote = fetchQuoteFromAPI()
//        Log.d("Fe", "Quotes Fetched")
        // Save the new quote in SharedPreferences
        val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("quote", newQuote).apply()

        // Trigger the widget update
        QuoteGlanceWidget().update(context, glanceId)
    }

    private suspend fun fetchQuoteBasedOnPreference(context: Context): String {
        return withContext(Dispatchers.IO) {
            val isApiEnabled = SettingsHelper.isApiQuotesEnabled(context)
            Log.d("Message", "The Api values is : ${isApiEnabled}")
            return@withContext if (isApiEnabled) {
                fetchQuoteFromAPI()
            } else {
                fetchQuoteFromFlutter(context)
            }
        }
    }
    private suspend fun fetchQuoteFromAPI(): String = withContext(Dispatchers.IO) {
        try {
            val url = URL("https://staticapis.pragament.com/daily/quotes-en-gratitude.json")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connect()

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val quotesArray = JSONObject(response).getJSONArray("quotes")
                val randomIndex = (0 until quotesArray.length()).random()
                val quoteObject = quotesArray.getJSONObject(randomIndex)
                return@withContext quoteObject.getString("quote")
            } else {
                return@withContext "Error fetching quote"
            }
        } catch (e: Exception) {
            return@withContext "Error fetching quote"
        }
    }
    private fun fetchQuoteFromFlutter(context: Context): String {
        var quote = "Error fetching quote"
        val handler = Handler(Looper.getMainLooper())

        val latch = CountDownLatch(1) // To synchronize the main thread call
        handler.post {
            try {
                val flutterEngine = FlutterEngine(context).apply {
                    dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
                }
                val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "quote_channel")
                Log.d("fetchQuoteFromFlutter", "MethodChannel initialized")

                methodChannel.invokeMethod("getQuoteFromHive", null, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        quote = result as? String ?: "No quotes found."
                        Log.d("fetchQuoteFromFlutter", "Fetched quote: $quote")
                        latch.countDown() // Signal completion
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        quote = "Error: $errorMessage"
                        latch.countDown() // Signal completion
                    }

                    override fun notImplemented() {
                        quote = "Method not implemented"
                        latch.countDown() // Signal completion
                    }
                })
            } catch (e: Exception) {
                Log.e("fetchQuoteFromFlutter", "Error fetching quote: ${e.message}")
                latch.countDown() // Signal completion
            }
        }

        latch.await() // Wait for the main thread to finish processing
        return quote
    }

}


