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
  static const String _apiUrl =
      'https://staticapis.pragament.com/daily/quotes-en-gratitude.json';

  String _currentQuote = "Fetching...";
  bool _isFetching = false;
  List<QuoteModel> _customQuotes = [];

  String get currentQuote => _currentQuote;
  bool get isFetching => _isFetching;
  List<QuoteModel> get customQuotes => _customQuotes;

  QuoteProvider() {
    _loadCustomQuotes();
  }

  Future<void> _loadCustomQuotes() async {
    try {
      final box = Hive.box<QuoteModel>('quotesBox');
      _customQuotes = box.values.toList();
    } catch (e) {
      debugPrint("Error loading quotes from Hive: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> addQuote(
      String quote, List<TagModel> tags, String description) async {
    try {
      final box = Hive.box<QuoteModel>('quotesBox');
      final newQuote = QuoteModel(
        id: const Uuid().v4(),
        quote: quote,
        tags: tags,
        description: description,
      );
      await box.add(newQuote);
      _customQuotes.add(newQuote);
    } catch (e) {
      debugPrint("Error adding new quote: $e");
    } finally {
      notifyListeners();
    }
  }

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
    } catch (e) {
      debugPrint("Error fetching quote: ${e.toString()}");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFromApi() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final quotes = data['quotes'] as List<dynamic>;
        if (quotes.isNotEmpty) {
          _currentQuote = quotes[Random().nextInt(quotes.length)]['quote'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching quotes from API: $e");
    }
  }

  Future<void> _fetchFromHive(List<String>? selectedTags) async {
    try {
      final box = Hive.box<QuoteModel>('quotesBox');
      if (box.isNotEmpty) {
        final matchingQuotes =
            _filterQuotesByTags(box.values.toList(), selectedTags);
        if (matchingQuotes.isNotEmpty) {
          _currentQuote =
              matchingQuotes[Random().nextInt(matchingQuotes.length)].quote;
        }
      }
    } catch (e) {
      debugPrint("Error fetching quotes from Hive: $e");
    }
  }

  Future<String> fetchRandomQuote(List<String>? selectedTags) async {
    await Future.delayed(const Duration(milliseconds: 700));
    try {
      final box = Hive.box<QuoteModel>('quotesBox');
      if (box.isNotEmpty) {
        final matchingQuotes =
            _filterQuotesByTags(box.values.toList(), selectedTags);
        if (matchingQuotes.isNotEmpty) {
          return matchingQuotes[Random().nextInt(matchingQuotes.length)].quote;
        }
      }
    } catch (e) {
      debugPrint("Error fetching quotes: $e");
    }
    return _currentQuote;
  }

  Future<void> addTagToQuote(String quoteId, TagModel tag) async {
    try {
      final box = Hive.box<QuoteModel>('quotesBox');
      final index = _customQuotes.indexWhere((quote) => quote.id == quoteId);
      if (index != -1) {
        final updatedQuote = _customQuotes[index];
        updatedQuote.tags.add(tag);
        await box.putAt(index, updatedQuote);
        _customQuotes[index] = updatedQuote;
      }
    } catch (e) {
      debugPrint("Error adding tag to quote: $e");
    } finally {
      notifyListeners();
    }
  }

  List<QuoteModel> _filterQuotesByTags(
      List<QuoteModel> quotes, List<String>? selectedTags) {
    if (selectedTags == null || selectedTags.isEmpty) {
      return quotes;
    }
    return quotes.where((quote) {
      final quoteTags = quote.tags.map((tag) => tag.name).toSet();
      return selectedTags.any(quoteTags.contains);
    }).toList();
  }
}
