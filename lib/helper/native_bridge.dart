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
        final List<String> tags = List<String>.from(call.arguments['tags']); // Get the tags from Android
        return await _getSortedQuoteFromHive(index, order, tags);
      }
      return null;
    });
  }

  static Future<String> _getSortedQuoteFromHive(int index, String order, List<String> tags) async {
    final box = Hive.box<QuoteModel>('quotesBox');
    if (box.isNotEmpty) {
      List<QuoteModel> quotesList = box.values.toList().cast<QuoteModel>();

      // Debug: Log all quotes and their tags
      print("All Quotes in Hive:");
      for (var quote in quotesList) {
        print(
          "Quote: ${quote.quote}, Tags: ${quote.tags.map((tag) => tag.name).toList()}",
        );
      }

      // Sort quotes based on the provided order
      quotesList.sort((a, b) {
        if (order.toLowerCase() == "ascending") {
          return a.quote.compareTo(b.quote);
        } else if (order.toLowerCase() == "descending") {
          return b.quote.compareTo(a.quote);
        } else {
          return 0; // Default: no sorting
        }
      });

      // Filter quotes that match at least one of the tags
      final filteredQuotes = quotesList.where((quoteModel) {
        for (String tag in tags) {
          // Compare input tag with `TagModel` name field
          if (quoteModel.tags.any((quoteTag) =>
          quoteTag.name.trim().toLowerCase() == tag.trim().toLowerCase())) {
            print("Matching Quote Found: ${quoteModel.quote} for Tag: $tag");
            return true; // Match found, include this quote
          }
        }
        return false;
      }).toList();

      // Debug: Log filtered quotes
      print("Total Matching Quotes for Tags $tags: ${filteredQuotes.length}");

      // If there are filtered quotes, return the one at the specified index
      if (filteredQuotes.isNotEmpty) {
        final randomIndex = index % filteredQuotes.length;
        return filteredQuotes[randomIndex].quote;
      }
    }
    return "No matching quote found.";
  }
}

