import 'dart:math';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/quote_model.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('quote_channel');

  static void registerMethods() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "getQuoteFromHive") {
        return await _getRandomHiveQuote();
      }
      return null;
    });
  }

  static Future<String> _getRandomHiveQuote() async {
    final box = Hive.box<QuoteModel>('quotesBox');
    if (box.isNotEmpty) {
      final randomIndex = Random().nextInt(box.length);
      return box.getAt(randomIndex)?.quote ?? "No quotes found.";
    }
    return "No quotes found.";
  }
}
