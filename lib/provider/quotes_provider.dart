import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../helper/settings_helper.dart';
import '../models/quote_model.dart';


class QuoteProvider with ChangeNotifier {
  static const String _apiUrl = 'https://staticapis.pragament.com/daily/quotes-en-gratitude.json';
  String _currentQuote = "Fetching...";
  bool _isFetching = false;
  List<QuoteModel> _customQuotes = [];

  String get currentQuote => _currentQuote;
  bool get isFetching => _isFetching;
  List<QuoteModel> get customQuotes => _customQuotes;

  QuoteProvider() {
    _loadCustomQuotes();
  }

  // Load quotes from Hive into _customQuotes
  Future<void> _loadCustomQuotes() async {
    final box = Hive.box<QuoteModel>('quotesBox');
    _customQuotes = box.values.toList();
    notifyListeners();
  }

  // Add a new quote to Hive and update the provider state
  Future<void> addQuote(String quote) async {
    final box = Hive.box<QuoteModel>('quotesBox');
    final newQuote = QuoteModel(
      id: const Uuid().v4(), // Generate a unique ID
      quote: quote,
    );
    await box.add(newQuote);
    _customQuotes.add(newQuote);
    notifyListeners();
  }

  // Fetch quotes from the API or Hive
  Future<void> fetchQuote() async {
    _isFetching = true;
    notifyListeners();

    try {
      final isApiEnabled = await SettingsHelper.isApiQuotesEnabled();
      if (isApiEnabled) {
        await _fetchFromApi();
      } else {
        await _fetchFromHive();
      }
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  // Fetch quotes from the API
  Future<void> _fetchFromApi() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quotes = data['quotes'] as List;
        if (quotes.isNotEmpty) {
          _currentQuote = quotes[Random().nextInt(quotes.length)]['quote'];
        } else {
          _currentQuote = "No quotes available.";
        }
      } else {
        _currentQuote = "Failed to fetch quote.";
      }
    } catch (e) {
      _currentQuote = "Error: ${e.toString()}";
    }
  }

  // Fetch a random quote from the Hive database
  Future<void> _fetchFromHive() async {
    try {
      final box = Hive.box<QuoteModel>('quotesBox');
      if (box.isNotEmpty) {
        final randomIndex = Random().nextInt(box.length);
        _currentQuote = box.getAt(randomIndex)?.quote ?? "No quotes found.";
      } else {
        _currentQuote = "No quotes found.";
      }
    } catch (e) {
      _currentQuote = "Error fetching local quotes: ${e.toString()}";
    }
  }
}


