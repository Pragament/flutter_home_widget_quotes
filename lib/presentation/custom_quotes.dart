import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/quote_model.dart';
import '../provider/quotes_provider.dart';

class CustomQuotes extends StatefulWidget {
  const CustomQuotes({Key? key}) : super(key: key);

  @override
  State<CustomQuotes> createState() => _CustomQuotesState();
}

class _CustomQuotesState extends State<CustomQuotes> {
  final TextEditingController _searchController = TextEditingController();
  List<QuoteModel> _filteredQuotes = [];
  List<QuoteModel> _allQuotes = [];

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _searchController.addListener(_filterQuotes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterQuotes);
    _searchController.dispose();
    super.dispose();
  }

  void _loadQuotes() {
    final Box<QuoteModel> quoteBox = Hive.box<QuoteModel>('quotesBox');
    setState(() {
      _allQuotes = quoteBox.values.toList();
      _filteredQuotes = List.from(_allQuotes);
    });
  }

  void _filterQuotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredQuotes = _allQuotes
          .where((quote) => quote.quote.toLowerCase().contains(query))
          .toList();
    });
  }

  void _showDeleteDialog(BuildContext context, int boxIndex, Box<QuoteModel> quoteBox) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Quote"),
          content: const Text("Are you sure you want to delete this quote?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await quoteBox.deleteAt(boxIndex);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quote deleted successfully')),
                );
                _loadQuotes();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Box<QuoteModel> box, int index, QuoteModel quote) {
    final TextEditingController controller = TextEditingController(text: quote.quote);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Quote'),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Quote',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedQuote = controller.text.trim();
                if (updatedQuote.isNotEmpty) {
                  final updatedModel = QuoteModel(id: quote.id, quote: updatedQuote);
                  await box.putAt(index, updatedModel);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quote updated successfully')),
                  );
                  _loadQuotes();
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addQuote(String quote) async {
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    await quoteProvider.addQuote(quote);
    print("Quote added successfully: $quote");
    _loadQuotes();
  }

  void _showAddQuoteDialog() {
    final TextEditingController quoteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a New Quote'),
          content: TextField(
            controller: quoteController,
            decoration: const InputDecoration(
              hintText: 'Enter your quote here',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final quote = quoteController.text.trim();
                if (quote.isNotEmpty) {
                  _addQuote(quote);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<QuoteModel> quoteBox = Hive.box<QuoteModel>('quotesBox');

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuoteDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quotes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: quoteBox.listenable(),
              builder: (context, Box<QuoteModel> box, _) {
                if (_filteredQuotes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No quotes found.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _filteredQuotes.length,
                  itemBuilder: (context, index) {
                    final quote = _filteredQuotes[index];
                    final boxIndex = _allQuotes.indexOf(quote);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          title: Text(
                            quote.quote,
                            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteDialog(context, boxIndex, quoteBox),
                          ),
                          onTap: () => _showEditDialog(context, quoteBox, boxIndex, quote),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
