import 'dart:math';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/quote_model.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('quote_channel');

  static void registerMethods() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "getQuoteFromHive") {
        final int index = call.arguments['index'];
        final String order = call.arguments['order'];
        return await _getSortedQuoteFromHive(index, order);
      }
      return null;
    });
  }

  static Future<String> _getSortedQuoteFromHive(int index, String order) async {
    final box = Hive.box<QuoteModel>('quotesBox');
    if (box.isNotEmpty) {
      List<QuoteModel> quotesList = box.values.toList().cast<QuoteModel>();

      // Sort the quotes based on the provided order
      quotesList.sort((a, b) {
        if (order == "ascending") {
          return a.quote.compareTo(b.quote);
        } else if (order == "descending") {
          return b.quote.compareTo(a.quote);
        } else {
          return 0; // Default: no sorting
        }
      });

      // Get the quote at the specified index
      final randomIndex = index % quotesList.length;
      return quotesList[randomIndex].quote;
    }
    return "No quotes found.";
  }
}
