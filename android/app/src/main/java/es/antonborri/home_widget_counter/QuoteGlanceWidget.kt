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
                    val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
                    val prefs1 = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val order: String = prefs1.getString("flutter.order", "Random").toString()
                    if (!prefs.contains("order_$glanceId")){
                        prefs.edit().putString("order_$glanceId", order).apply()
                        prefs.edit().putInt("index_$glanceId", 0).apply()
                    }
                    val order1: String = prefs.getString("order_$glanceId", "Random").toString()
                    val index: Int = prefs.getInt("index_$glanceId", 0)

                    val newQuote = fetchQuoteBasedOnPreference(context,index,order1)

//                    val prefs =
//                        context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putString("quote", newQuote).apply()
                    prefs.edit().putInt("index_$glanceId",(index+1)%Int.MAX_VALUE).apply()

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

    private suspend fun fetchQuoteBasedOnPreference(context: Context,index:Int,order: String): String {
        return withContext(Dispatchers.IO) {
            val isApiEnabled = SettingsHelper.isApiQuotesEnabled(context)
//            Log.d("Message", "The Api values is : ${isApiEnabled}")
            return@withContext if (isApiEnabled) {
//                fetchQuoteFromFlutter(context)
                fetchQuoteFromAPI(index,order)
            } else {
                fetchQuoteFromFlutter(context,index,order)
            }
        }
    }

    private fun fetchQuoteFromAPI(index: Int,order:String): String {
        return try {
            val url = URL("https://staticapis.pragament.com/daily/quotes-en-gratitude.json")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connect()

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val quotesArray = JSONObject(response).getJSONArray("quotes")
                //val randomIndex = (0 until quotesArray.length()).random()
                val randomIndex = index % quotesArray.length()
                Log.d("index",randomIndex.toString())
                val quotesList = mutableListOf<String>()
                for (i in 0 until quotesArray.length()) {
                    val quoteObject = quotesArray.getJSONObject(i)
                    quotesList.add(quoteObject.getString("quote"))
                }

                // Sort the list based on the order
                val sortedQuotes = when (order) {
                    "Ascending" -> quotesList.sorted()
                    "Descending" -> quotesList.sortedDescending()
                    else -> quotesList.shuffled() // Default to random order
                }
//                val quoteObject = quotesArray.getJSONObject(randomIndex)
//                quoteObject.getString("quote")
                sortedQuotes[randomIndex]
            } else {
                "Error fetching quote from API."
            }
        } catch (e: Exception) {
            "Error fetching quote from API."
        }
    }

    private fun fetchQuoteFromFlutter(context: Context,index: Int,order: String): String {
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
                val arguments = mapOf("index" to index, "order" to order)

                methodChannel.invokeMethod("getQuoteFromHive", arguments, object : MethodChannel.Result {
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
        Log.d("key", "fontSize_$glanceId");

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
                    style = TextStyle(fontSize = fontSize1.toFloat().sp,textAlign = TextAlign.Center, fontStyle = FontStyle.Italic),
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
        val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
        val prefs1 = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val order1: String = prefs.getString("order_$glanceId", "Random").toString()
        val index: Int = prefs.getInt("index_$glanceId", 0)
        val newQuote = fetchQuoteBasedOnPreference(context,index,order1)

//        Log.d("Fe", "Quotes Fetched")
        // Save the new quote in SharedPreferences
//        val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("quote", newQuote).apply()
        prefs.edit().putInt("index_$glanceId",(index+1)%Int.MAX_VALUE).apply()

        // Trigger the widget update
        QuoteGlanceWidget().update(context, glanceId)
    }

    private suspend fun fetchQuoteBasedOnPreference(context: Context,index: Int,order: String): String {
        return withContext(Dispatchers.IO) {
            val isApiEnabled = SettingsHelper.isApiQuotesEnabled(context)
            Log.d("Message", "The Api values is : ${isApiEnabled}")
            return@withContext if (isApiEnabled) {
                fetchQuoteFromAPI(index,order)
            } else {
                fetchQuoteFromFlutter(context,index,order)
            }
        }
    }
    private suspend fun fetchQuoteFromAPI(index: Int,order: String): String = withContext(Dispatchers.IO) {
        try {
            val url = URL("https://staticapis.pragament.com/daily/quotes-en-gratitude.json")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connect()

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val quotesArray = JSONObject(response).getJSONArray("quotes")
                //val randomIndex = (0 until quotesArray.length()).random()
                val randomIndex = index % quotesArray.length()
                Log.d("index",randomIndex.toString())
                val quotesList = mutableListOf<String>()
                for (i in 0 until quotesArray.length()) {
                    val quoteObject = quotesArray.getJSONObject(i)
                    quotesList.add(quoteObject.getString("quote"))
                }

                // Sort the list based on the order
                val sortedQuotes = when (order) {
                    "Ascending" -> quotesList.sorted()
                    "Descending" -> quotesList.sortedDescending()
                    else -> quotesList.shuffled() // Default to random order
                }
//                val quoteObject = quotesArray.getJSONObject(randomIndex)
//                Log.d("check","From action callback.")
//                return@withContext quoteObject.getString("quote")
                return@withContext sortedQuotes[randomIndex]
            } else {
                return@withContext "Error fetching quote"
            }
        } catch (e: Exception) {
            return@withContext "Error fetching quote"
        }
    }
    private fun fetchQuoteFromFlutter(context: Context,index: Int,order: String): String {
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
                val arguments = mapOf("index" to index, "order" to order)

                methodChannel.invokeMethod("getQuoteFromHive", arguments, object : MethodChannel.Result {
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