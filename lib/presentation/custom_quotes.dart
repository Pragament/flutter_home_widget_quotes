import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget_counter/models/tag_model.dart';
import 'package:provider/provider.dart';
import '../models/quote_model.dart';
import '../provider/quotes_provider.dart';
import '../provider/tag_provider.dart';
import '../widgets/dialogs/show_tag_search.dart';
import '../widgets/tags_selection_dialog.dart';

class CustomQuotes extends StatefulWidget {
  final List<String> selectedTagNames;
  const CustomQuotes({Key? key, required this.selectedTagNames}) : super(key: key);

  @override
  State<CustomQuotes> createState() => _CustomQuotesState();
}

class _CustomQuotesState extends State<CustomQuotes> {
  final TextEditingController _searchController = TextEditingController();
  List<QuoteModel> _filteredQuotes = [];
  List<QuoteModel> _allQuotes = [];

  GlobalKey tagsKey = GlobalKey();
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
      // Re-fetch quotes when selectedTagNames changes
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
      _filteredQuotes = (selectedTagNames.isEmpty || selectedTagNames.length==tags.length)
          ? List.from(_allQuotes) // Fetch all if no tags are selected
          : _allQuotes.where((quote) {
        final quoteTags = quote.tags.map((tag) => tag.name).toSet();
        final val = selectedTagNames.any((tag) => quoteTags.contains(tag));
        print("Number of selected tags: $val");
        return val;
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

  void _showEditDialog(BuildContext context, Box<QuoteModel> box, int index, QuoteModel quote) {
    final TextEditingController controller = TextEditingController(text: quote.quote);
    List<TagModel> selectedTags = List.from(quote.tags); // Copy the existing tags for editing

    showDialog(
      context: context,
      builder: (BuildContext context) {
        print("Quote Editable: ${quote.id}, ${quote.tags}");
        return AlertDialog(
          title: const Text('Edit Quote'),
          content: SizedBox(
            height: 180,
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Quote',
                    border: OutlineInputBorder(),
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
              onPressed: () async {
                final updatedQuote = controller.text.trim();
                if (updatedQuote.isNotEmpty) {
                  final updatedModel = QuoteModel(id: quote.id, quote: updatedQuote, tags: selectedTags);
                  await box.putAt(index, updatedModel);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quote updated successfully')),
                  );
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

  Future<void> _addQuote(String quote) async {
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    await quoteProvider.addQuote(quote, selectedTags);
    _loadQuotes(widget.selectedTagNames);
  }

  void _showAddQuoteDialog() {
    final TextEditingController quoteController = TextEditingController();
    selectedTags = [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a New Quote'),
          content: Container(
            height: 200,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                TextField(
                  controller: quoteController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your quote here',
                  ),
                ),
                ShowTagSearch(selectedTags: selectedTags)
              ],
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
