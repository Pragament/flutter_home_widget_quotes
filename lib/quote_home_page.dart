
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import 'package:home_widget_counter/models/tag_model.dart';
import 'package:home_widget_counter/presentation/custom_quotes.dart';
import 'package:home_widget_counter/provider/quotes_provider.dart';
import 'package:home_widget_counter/provider/tag_provider.dart';
import 'package:home_widget_counter/widgets/dialogs/widget_config_dialog.dart';
import 'package:provider/provider.dart';
import 'helper/settings_helper.dart';
import 'models/quote_model.dart';
import 'package:path_provider/path_provider.dart';


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
  List<TagModel> tags = [];
  List<bool> selectedTags = [];
  bool allSelected = true;
  List<String> selectedTagNames = [];
  Timer? _wallpaperChangeTimer;
  bool isApiEnable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    quoteBox = Hive.box<QuoteModel>('quotesBox');

    // Trigger data fetch only after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuoteProvider>(context, listen: false).fetchQuote();
    });
    _initializeApiSettings();
    loadTags();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      Provider.of<QuoteProvider>(context, listen: false).fetchQuote();
    }
  }

  Future<void> _initializeApiSettings() async {
    isApiEnable = await SettingsHelper.isApiQuotesEnabled();
    if (isApiEnable) {
      _startWallpaperChangeTimer();
    }
    setState(() {});
  }
  void _startWallpaperChangeTimer() {
    _wallpaperChangeTimer =
        Timer.periodic(const Duration(minutes: 1), (_) async {
          if (isApiEnable) {
            final quoteProvider =
            Provider.of<QuoteProvider>(context, listen: false);
            await quoteProvider.fetchQuote();
            final newQuote = quoteProvider.currentQuote;
            await _setLiveWallpaper(newQuote);
          }
        });
  }

  Future<void> _setLiveWallpaper(String quote) async {
    try {
      List<String> words = quote.split(' ');
      String animatedText = '';
      int index = 0;

      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (index < words.length) {
          animatedText += '${words[index]} ';
          index++;
          final imageFile = await _generateQuoteImage(animatedText.trim());
          await WallpaperManager.setWallpaperFromFile(
            imageFile.path,
            WallpaperManager.HOME_SCREEN,
          );
        } else {
          timer.cancel();
        }
      });

      final imageFile = await _generateQuoteImage(quote);
      await WallpaperManager.setWallpaperFromFile(
        imageFile.path,
        WallpaperManager.LOCK_SCREEN,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set wallpaper: $e'),
        ),
      );
    }
  }

  Future<File> _generateQuoteImage(String quote) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(Offset.zero, Offset(screenWidth, screenHeight)),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenWidth, screenHeight),
      Paint()..color = Colors.white,
    );

    double fontSize = 40.0;
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );

    final textSpan = TextSpan(text: quote, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: screenWidth * 0.8);
    final offset = Offset(
      (screenWidth - textPainter.width) / 2,
      (screenHeight - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final img =
    await picture.toImage(screenWidth.toInt(), screenHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/quote_image.png');
    await file.writeAsBytes(buffer);
    return file;
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wallpaperChangeTimer?.cancel();
    super.dispose();
  }

  //Helper method to get a random quote from Hive
  String? _getRandomQuote() {
    final quoteBox = Hive.box<QuoteModel>('quotesBox');
    if (quoteBox.isEmpty) return null;
    final randomIndex = Random().nextInt(quoteBox.length);
    return quoteBox
        .getAt(randomIndex)
        ?.quote;
  }

  void loadTags() {
    final tagProvider = Provider.of<TagProvider>(context, listen: false);
    setState(() {
      tags = tagProvider.tags;
      selectedTags = List.filled(tags.length, false);
    });
  }

  void toggleTagSelection(int index, bool value) {
    setState(() {
      selectedTags[index] = value;
      allSelected = selectedTags.every((selected) => selected);
      _fetchAndDisplayQuote();
    });
  }

  void toggleAllTags() {
    setState(() {
      allSelected = !allSelected;
      selectedTags = List<bool>.filled(tags.length, allSelected);
      _fetchAndDisplayQuote();
    });
  }

  Future<void> _fetchAndDisplayQuote() async {
    final provider = Provider.of<QuoteProvider>(context, listen: false);

    // Get the names of the selected tags
    selectedTagNames = selectedTags
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => tags[entry.key].name)
        .toList();
    print("Selected tag length: ${selectedTagNames.length}");
    await provider.fetchQuote(tags: selectedTagNames);

    setState(() {});
    await HomeWidget.saveWidgetData(_quoteKey, provider.currentQuote);
    await HomeWidget.updateWidget(
      iOSName: 'QuoteWidget',
      androidName: 'QuoteWidgetProvider',
    );
    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(androidName: 'QuoteGlanceWidgetReceiver');
    }
  }

  // Future<void> _fetchNewQuote() async {
  //   await Provider.of<QuoteProvider>(context, listen: false).fetchQuote();
  // }

  Future<void> _requestToPinWidget() async {
    final isRequestPinSupported = await HomeWidget
        .isRequestPinWidgetSupported();
    // print(isRequestPinSupported);
    if (isRequestPinSupported == true) {
      await HomeWidget.requestPinWidget(
        androidName: 'QuoteGlanceWidgetReceiver',
      );
    }
  }

  Widget _buildTagsStrip(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox(); // Return an empty widget if tags are not loaded
    }
    if (tags.length != selectedTags.length) {
      loadTags();
      setState(() {});
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black45),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        child: Icon(allSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank),
                        onTap: () {
                          toggleAllTags();
                        },
                      ),
                      const Text(
                        'Select All',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(tags.length, (index) {
                    final tag = tags[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black45),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            child: Icon(selectedTags[index]
                                ? Icons.check_box
                                : Icons.check_box_outline_blank),
                            onTap: () {
                              toggleTagSelection(index, !selectedTags[index]);
                            },
                          ),
                          Text(
                            tag.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
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
                  Row(
                    children: [
                      _buildTagsStrip(context),
                    ],
                  ),
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
                            style: const TextStyle(
                                fontSize: 20, fontStyle: FontStyle.italic),
                          );
                        }
                      } else {
                        // Simulate loading state for Hive quotes
                        return FutureBuilder<String?>(
                          future: QuoteProvider().fetchRandomQuote(
                              selectedTagNames),
                          // Fetch quote from the function
                          builder: (context, localSnapshot) {
                            if (localSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator(); // Show progress while loading the quote
                            }

                            if (localSnapshot.hasError) {
                              return const Text(
                                'Error fetching local quote',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 20, fontStyle: FontStyle.italic),
                              );
                            }

                            if (localSnapshot.hasData) {
                              // Once data is available, show the quote
                              final randomQuote = localSnapshot
                                  .data; // This will be the quote fetched from `fetchRandomQuote`
                              return Text(
                                randomQuote ?? "No quote found.",
                                // If no quote found, show a fallback message
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 20, fontStyle: FontStyle.italic),
                              );
                            }

                            // In case no data and no error, show fallback message
                            return const Text(
                              'No quote found',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 20, fontStyle: FontStyle.italic),
                            );
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30,),
                  ElevatedButton(
                    onPressed: _fetchAndDisplayQuote,
                    child: const Text('Fetch New Quote'),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await showForm(context, "Widget Configuration");
                    },
                    child: const Text('Pin Widget to Home Screen'),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () async {
                      if (isApiEnable && quoteProvider.currentQuote.isNotEmpty) {
                        await _setLiveWallpaper(quoteProvider.currentQuote);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('Wallpaper set successfully!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.red,
                            content:
                            Text('Failed: Enable API or no quotes available'),
                          ),
                        );
                      }
                    },
                    child: const Text('Set Quote to Wallpaper'),
                  ),
                  const SizedBox(height: 15,),
                  Expanded(child: CustomQuotes(
                    selectedTagNames: selectedTagNames,
                  )
                  )
                ],
              ),
            ),
          ),
        ));
  }

}