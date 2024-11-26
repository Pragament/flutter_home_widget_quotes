import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import 'package:home_widget_counter/presentation/custom_quotes.dart';
import 'package:home_widget_counter/provider/quotes_provider.dart';
import 'package:home_widget_counter/widgets/dialogs/widget_config_dialog.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'helper/settings_helper.dart';
import 'models/quote_model.dart';


@pragma('vm:entry-point')
Future<void> interactiveCallback(Uri? uri) async {
  await HomeWidget.setAppGroupId('group.es.antonborri.homeWidgetCounter');
  if (uri?.host == 'fetchQuote') {
    await _fetchAndDisplayQuote();
  }
}

const _quoteKey = 'quote';

Future<void> _fetchAndDisplayQuote() async {
  final provider = QuoteProvider();
  await provider.fetchQuote();
  await HomeWidget.saveWidgetData(_quoteKey, provider.currentQuote);
  await HomeWidget.updateWidget(
    iOSName: 'QuoteWidget',
    androidName: 'QuoteWidgetProvider',
  );
  if (Platform.isAndroid) {
    await HomeWidget.updateWidget(androidName: 'QuoteGlanceWidgetReceiver');
  }
}

class QuoteHomePage extends StatefulWidget {
  const QuoteHomePage({super.key, required this.title});
  final String title;

  @override
  State<QuoteHomePage> createState() => _QuoteHomePageState();
}

class _QuoteHomePageState extends State<QuoteHomePage> with WidgetsBindingObserver {
  late Box<QuoteModel> quoteBox;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    quoteBox = Hive.box<QuoteModel>('quotesBox');

    // Trigger data fetch only after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuoteProvider>(context, listen: false).fetchQuote();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      Provider.of<QuoteProvider>(context, listen: false).fetchQuote();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetchNewQuote() async {
    await Provider.of<QuoteProvider>(context, listen: false).fetchQuote();
  }

  Future<void> _requestToPinWidget() async {
    final isRequestPinSupported = await HomeWidget.isRequestPinWidgetSupported();
    // print(isRequestPinSupported);
    if (isRequestPinSupported == true) {
      await HomeWidget.requestPinWidget(
        androidName: 'QuoteGlanceWidgetReceiver',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = Provider.of<QuoteProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          FutureBuilder<bool>(
            future: SettingsHelper.isApiQuotesEnabled(),
            builder: (context, snapshot) {
              final isApiEnabled = snapshot.data ?? true;
              return Switch(
                value: isApiEnabled,
                onChanged: (value) async {
                  await SettingsHelper.setApiQuotesEnabled(value);
                  setState(() {}); // Refresh UI
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: SizedBox(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Current Quote:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                FutureBuilder<bool>(
                  future: SettingsHelper.isApiQuotesEnabled(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator(); // Show progress while loading settings
                    }

                    final isApiEnabled = snapshot.data ?? true;

                    if (isApiEnabled) {
                      if (quoteProvider.isFetching) {
                        return const CircularProgressIndicator(); // Show progress while fetching from API
                      } else {
                        return Text(
                          quoteProvider.currentQuote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                        );
                      }
                    } else {
                      // Simulate loading state for Hive quotes
                      final localQuoteFuture = Future.delayed(
                        const Duration(milliseconds: 700),
                        _getRandomQuote,
                      );

                      return FutureBuilder<String?>(
                        future: localQuoteFuture,
                        builder: (context, localSnapshot) {
                          if (localSnapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator(); // Show progress while loading local quote
                          }

                          if (localSnapshot.hasError) {
                            return const Text(
                              'Error fetching local quote',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                            );
                          }

                          final randomQuote = localSnapshot.data;
                          return Text(
                            randomQuote ?? 'No quotes available locally',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                          );
                        },
                      );
                    }
                  },
                ),
              const SizedBox(height: 30,),
              ElevatedButton(
                onPressed: _fetchNewQuote,
                child: const Text('Fetch New Quote'),
              ),
              GestureDetector(
                onTap: () async {
                  await showForm(context, "Widget Configuration");
                },
                child: const Text('Pin Widget to Home Screen'),
              ),
            ],
          ),
        ),
      ),
    ));
  }

//Helper method to get a random quote from Hive
  String? _getRandomQuote() {
    final quoteBox = Hive.box<QuoteModel>('quotesBox');
    if (quoteBox.isEmpty) return null;
    final randomIndex = Random().nextInt(quoteBox.length);
    return quoteBox.getAt(randomIndex)?.quote;
  }

}
