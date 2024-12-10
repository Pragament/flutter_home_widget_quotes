import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/quote_model.dart';
import '../models/tag_model.dart';
import '../provider/quotes_provider.dart';
import '../provider/tag_provider.dart';
import '../widgets/dialogs/show_tag_search.dart';

class CustomQuotes extends StatefulWidget {
  final List<String> selectedTagNames;

  const CustomQuotes({Key? key, required this.selectedTagNames})
      : super(key: key);

  @override
  State<CustomQuotes> createState() => _CustomQuotesState();
}

class _CustomQuotesState extends State<CustomQuotes> {
  final TextEditingController _searchController = TextEditingController();
  List<QuoteModel> _filteredQuotes = [];
  List<QuoteModel> _allQuotes = [];
  List<TagModel> tags = [];
  List<TagModel> selectedTags = [];

  @override
  void initState() {
    super.initState();
    loadTags();
    _loadQuotes(widget.selectedTagNames);
    _searchController.addListener(_filterQuotes);
  }

  @override
  void didUpdateWidget(CustomQuotes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTagNames != widget.selectedTagNames) {
      _loadQuotes(widget.selectedTagNames);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterQuotes);
    _searchController.dispose();
    super.dispose();
  }

  void loadTags() {
    final tagProvider = Provider.of<TagProvider>(context, listen: false);
    setState(() {
      tags = tagProvider.tags;
    });
  }

  void _loadQuotes(List<String> selectedTagNames) {
    final Box<QuoteModel> quoteBox = Hive.box<QuoteModel>('quotesBox');
    setState(() {
      _allQuotes = quoteBox.values.toList();
      _filteredQuotes =
          (selectedTagNames.isEmpty || selectedTagNames.length == tags.length)
              ? List.from(_allQuotes)
              : _allQuotes.where((quote) {
                  final quoteTags = quote.tags.map((tag) => tag.name).toSet();
                  return selectedTagNames.any((tag) => quoteTags.contains(tag));
                }).toList();
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

  void _showAddQuoteDialog() {
    final TextEditingController quoteController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    selectedTags = [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a New Quote'),
          content: SizedBox(
            height: 250,
            child: Column(
              children: [
                TextField(
                  controller: quoteController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your quote',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter a description',
                  ),
                ),
                ShowTagSearch(selectedTags: selectedTags),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final quote = quoteController.text.trim();
                final description = descriptionController.text.trim();
                if (quote.isNotEmpty) {
                  _addQuote(quote, description);
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

  Future<void> _addQuote(String quote, String description) async {
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    await quoteProvider.addQuote(quote, selectedTags, description);
    _loadQuotes(widget.selectedTagNames);
  }

  void _showEditDialog(
      BuildContext context, Box<QuoteModel> box, int index, QuoteModel quote) {
    final TextEditingController quoteController =
        TextEditingController(text: quote.quote);
    final TextEditingController descriptionController =
        TextEditingController(text: quote.description ?? '');
    List<TagModel> selectedTags = List.from(quote.tags);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Quote'),
          content: SizedBox(
            height: 250,
            child: Column(
              children: [
                TextField(
                  controller: quoteController,
                  decoration: const InputDecoration(labelText: 'Quote'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                ShowTagSearch(selectedTags: selectedTags),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedQuote = quoteController.text.trim();
                final updatedDescription = descriptionController.text.trim();
                if (updatedQuote.isNotEmpty) {
                  final updatedModel = QuoteModel(
                    id: quote.id,
                    quote: updatedQuote,
                    tags: selectedTags,
                    description: updatedDescription,
                  );
                  await box.putAt(index, updatedModel);
                  _loadQuotes(widget.selectedTagNames);
                  setState(() {});
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

  void _showDeleteDialog(
      BuildContext context, int boxIndex, Box<QuoteModel> quoteBox) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Quote'),
          content: const Text('Are you sure you want to delete this quote?'),
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
                _loadQuotes(widget.selectedTagNames);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void showDescriptionDialog(BuildContext context, String? description) {
    if (description == null || description.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.only(bottom: 16),
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
                    child: Text('No quotes found.',
                        style: TextStyle(fontSize: 16)),
                  );
                }
                return ListView.builder(
                  itemCount: _filteredQuotes.length,
                  itemBuilder: (context, index) {
                    final quote = _filteredQuotes[index];
                    final boxIndex = _allQuotes.indexOf(quote);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          title: Text(
                            quote.quote,
                            style: const TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (quote.description !=
                                  null) // Check if description exists
                                quote.description!.isNotEmpty
                                    ? TextButton(
                                        onPressed: () {
                                          showDescriptionDialog(
                                            context,
                                            quote.description!,
                                          );
                                        },
                                        child: Text(
                                          "View Description",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      )
                                    : Text(
                                        'No Description',
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                      ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(
                                    context, boxIndex, quoteBox),
                              ),
                            ],
                          ),
                          onTap: () => _showEditDialog(
                              context, quoteBox, boxIndex, quote),
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
