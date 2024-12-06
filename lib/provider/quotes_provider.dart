import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../helper/settings_helper.dart';
import '../models/quote_model.dart';
import '../models/tag_model.dart';

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
  Future<void> addQuote(String quote, List<TagModel> tags) async {
    final box = Hive.box<QuoteModel>('quotesBox');
    final newQuote = QuoteModel(
      id: const Uuid().v4(),
      quote: quote,
      tags: tags,
    );
    await box.add(newQuote);

    // print("Quote saved with: ${newQuote.tags.length}");
    _customQuotes.add(newQuote);
    notifyListeners();
  }

  // Fetch quotes from the API or Hive
  Future<void> fetchQuote({List<String>? tags}) async {
    _isFetching = true;
    notifyListeners();

    try {
      final isApiEnabled = await SettingsHelper.isApiQuotesEnabled();
      if (isApiEnabled) {
        await _fetchFromApi();
      } else {
        await _fetchFromHive(tags);
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
      _currentQuote = "Error111 : ${e.toString()}";
      print("Error ${e.toString()}");
    }
  }

  Future<void> _fetchFromHive(List<String>? selectedTags) async {
    try {
      final box = Hive.box<QuoteModel>('quotesBox');

      if (box.isNotEmpty) {
        // Fetch all quotes or filter by selected tags
        final matchingQuotes = box.values.where((quote) {
          if (selectedTags == null || selectedTags.isEmpty) {
            // If no tags are provided, fetch all quotes
            return true;
          }

          final quoteTags = quote.tags.map((tag) => tag.name).toSet();
          return selectedTags.any(quoteTags.contains);
        }).toList();

        if (matchingQuotes.isNotEmpty) {
          // Pick a random quote from the matching quotes
          final randomIndex = Random().nextInt(matchingQuotes.length);
          _currentQuote = matchingQuotes[randomIndex].quote;
        } else {
          _currentQuote = "No matching quotes found.";
        }
      } else {
        _currentQuote = "No quotes found.";
      }
    } catch (e) {
      _currentQuote = "Error fetching local quotes: ${e.toString()}";
    }
  }

  Future<String> fetchRandomQuote(List<String>? selectedTags) async {
    await Future.delayed(
      const Duration(milliseconds: 700),
    );
    try {
      final box = Hive.box<QuoteModel>('quotesBox');

      if (box.isNotEmpty) {
        // Fetch all quotes or filter by selected tags
        final matchingQuotes = box.values.where((quote) {
          if (selectedTags == null || selectedTags.isEmpty) {
            return true;
          }

          final quoteTags = quote.tags.map((tag) => tag.name).toSet();
          return selectedTags.any((tag) => quoteTags.contains(tag));
        }).toList();

        if (matchingQuotes.isNotEmpty) {
          // Pick a random quote from the matching quotes
          final randomIndex = Random().nextInt(matchingQuotes.length);
          return matchingQuotes[randomIndex].quote; // Assuming QuoteModel has a 'quote' field
        } else {
          return "No matching quotes found.";
        }
      } else {
        return "No quotes found.";
      }
    } catch (e) {
      return "Error fetching local quotes: ${e.toString()}";
    }
  }

  // Add a tag to a specific quote
  Future<void> addTagToQuote(String quoteId, TagModel tag) async {
    final box = Hive.box<QuoteModel>('quotesBox');
    final index = _customQuotes.indexWhere((quote) => quote.id == quoteId);
    if (index != -1) {
      final updatedQuote = _customQuotes[index];
      updatedQuote.tags.add(tag);
      await box.putAt(index, updatedQuote);
      _customQuotes[index] = updatedQuote;
      notifyListeners();
    }
  }
}
