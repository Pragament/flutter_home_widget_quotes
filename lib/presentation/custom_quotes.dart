import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  File? attachment;

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
          .where((quote) => quote.quote.split('*').first.toLowerCase().contains(query))
          .toList();
    });
  }

  void _showAddQuoteDialog() {
    final TextEditingController quoteController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    Future pickImage(ImageSource source, Function setState) async {
      try {
        final image =
            await ImagePicker().pickImage(source: source, imageQuality: 100);
        if (image == null) return;
        final fileName = image.path.split('/').last;
        debugPrint(fileName);
        Directory dir = await getApplicationSupportDirectory();
        debugPrint('Original path: ${image.path}');
        debugPrint('Support dir: ${dir.path}');
        debugPrint('New file path: ${dir.path}/$fileName');
        final newFile = File('${dir.path}/$fileName');
        await image.saveTo(newFile.path);
        setState(() {
          attachment = newFile;
        });
      } catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    }

    selectedTags = [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add a New Quote'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            attachment != null
                                ? ListTile(
                                    leading:
                                        const Icon(Icons.image_search_rounded),
                                    title: const Text('View Image'),
                                    onTap: () {
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        showDragHandle: true,
                                        context: context,
                                        builder: ((context) =>
                                            FractionallySizedBox(
                                              heightFactor: 0.8,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.file(
                                                      attachment!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )),
                                      );
                                    },
                                  )
                                : const SizedBox(),
                            ListTile(
                              leading: const Icon(Icons.camera_alt_rounded),
                              title: const Text('Camera'),
                              onTap: () {
                                pickImage(ImageSource.camera, setState);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.image),
                              title: const Text('Gallery'),
                              onTap: () {
                                pickImage(ImageSource.gallery, setState);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 0.5,
                            color: Colors.black.withOpacity(0.65),
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: attachment == null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 50,
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'Add Sticker/GIF',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.55),
                                    ),
                                  ),
                                )
                              : Image.file(
                                  attachment!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: quoteController,
                    enableInteractiveSelection: true,
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
                onPressed: () {
                  attachment = null;
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final quote = quoteController.text.trim();
                  final description = descriptionController.text.trim();
                  if (quote.isNotEmpty) {
                    _addQuote(quote, description, attachment!.path);
                    setState(
                      () {
                        attachment = null;
                      },
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addQuote(
    String quote,
    String description,
    String attachmentPath,
  ) async {
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    await quoteProvider.addQuote(
      '$quote*$attachmentPath',
      selectedTags,
      description,
    );
    _loadQuotes(widget.selectedTagNames);
  }

  void _showEditDialog(
    BuildContext context,
    Box<QuoteModel> box,
    int index,
    QuoteModel quote,
  ) {
    final TextEditingController quoteController =
        TextEditingController(text: quote.quote.split('*').first);
    final TextEditingController descriptionController =
        TextEditingController(text: quote.description ?? '');
    List<TagModel> selectedTags = List.from(quote.tags);
    Future pickImage(ImageSource source, Function setState) async {
      try {
        final image = await ImagePicker().pickImage(source: source);
        if (image == null) return;
        final fileName = image.path.split('/').last;
        debugPrint('file name $fileName');
        Directory dir = await getApplicationSupportDirectory();
        debugPrint('dir $dir');
        final newFile = File('${dir.path}/$fileName');

        await image.saveTo(newFile.path);
        setState(() {
          attachment = newFile;
        });
      } catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Quote'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            attachment != null ||
                                    quote.quote.split('*').lastOrNull != null
                                ? ListTile(
                                    leading:
                                        const Icon(Icons.image_search_rounded),
                                    title: const Text('View Image'),
                                    onTap: () {
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        showDragHandle: true,
                                        context: context,
                                        builder: ((context) =>
                                            FractionallySizedBox(
                                              heightFactor: 0.8,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.file(
                                                      attachment ??
                                                          File(
                                                            quote.quote
                                                                .split('*')
                                                                .last,
                                                          ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )),
                                      );
                                    },
                                  )
                                : const SizedBox(),
                            ListTile(
                              leading: const Icon(Icons.camera_alt_rounded),
                              title: const Text('Camera'),
                              onTap: () {
                                pickImage(ImageSource.camera, setState);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.image),
                              title: const Text('Gallery'),
                              onTap: () {
                                pickImage(ImageSource.gallery, setState);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 0.5,
                            color: Colors.black.withOpacity(0.65),
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: attachment != null ||
                                  quote.quote.split('*').lastOrNull != null
                              ? Image.file(
                                  attachment ??
                                      File(quote.quote.split('*').last),
                                  fit: BoxFit.cover,
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 50,
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'Add Sticker/GIF',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.55),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
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
                onPressed: () {
                  attachment = null;
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updatedQuote = quoteController.text.trim();
                  final updatedDescription = descriptionController.text.trim();
                  if (updatedQuote.isNotEmpty) {
                    final updatedModel = QuoteModel(
                      id: quote.id,
                      quote:
                          '$updatedQuote*${attachment?.path ?? quote.quote.split('*').lastOrNull}',
                      tags: selectedTags,
                      description: updatedDescription,
                    );
                    await box.putAt(index, updatedModel);
                    _loadQuotes(widget.selectedTagNames);
                    setState(() {
                      attachment = null;
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    int boxIndex,
    Box<QuoteModel> quoteBox,
  ) {
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
          title: const Center(
            child: Text(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          leading: quote.quote.split('*').lastOrNull != null
                              ? Image.file(File(quote.quote.split('*').last))
                              : null,
                          title: Text(
                            quote.quote.split('*').first,
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
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
                                        child: const Text(
                                          'View Description',
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
                                  context,
                                  boxIndex,
                                  quoteBox,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showEditDialog(
                            context,
                            quoteBox,
                            boxIndex,
                            quote,
                          ),
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
