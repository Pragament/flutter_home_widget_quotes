import 'package:flutter/material.dart';
import 'package:home_widget_counter/models/tag_model.dart';
import 'package:provider/provider.dart';

import '../provider/tag_provider.dart';

class TagsSelectionDialog extends StatefulWidget {
  const TagsSelectionDialog({
    super.key,
    required this.selectedTags
  });

  final List<TagModel> selectedTags;

  @override
  State<TagsSelectionDialog> createState() => _TagsSelectionDialogState();
}

class _TagsSelectionDialogState extends State<TagsSelectionDialog> {
  List<TagModel> selectedTags = [];
  List<TagModel> allTags = [];
  List<TagModel> filteredTags = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedTags = widget.selectedTags;
    allTags = widget.selectedTags;
    loadTags();
  }

  /// Load tags from the provider
  void loadTags() {
    final tagProvider = Provider.of<TagProvider>(context, listen: false);
    setState(() {
      allTags = tagProvider.tags;
    });
    filterTags();
  }

  /// Filters tags based on the search query
  void filterTags() {
    setState(() {
      filteredTags = allTags
          .where((tag) => tag.name
          .toLowerCase()
          .contains(searchController.text.toLowerCase()))
          .toList();
    });
  }

  /// Update the parent widget using the callback
  void updateTags(TagModel tag, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedTags.add(tag);
      } else {
        selectedTags.removeWhere((t) => t.id == tag.id);
      }
    });

  }


  @override
  Widget build(BuildContext context) {
    final tagProvider = Provider.of<TagProvider>(context);
    return SizedBox(
      height: 500,
      width: 400,
      child: AlertDialog(
        scrollable: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select a Tag:',
              style: TextStyle(fontSize: 15),
            ),
            InkWell(
              onTap: () {
                final tagNameController = TextEditingController();
                final formKey = GlobalKey<FormState>();

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      "Enter tag name",
                      textAlign: TextAlign.center,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    content: SizedBox(
                      height: 125,
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                controller: tagNameController,
                                autofocus: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Cannot be empty';
                                  }
                                  return null;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Tag name',
                                  prefixIcon: Icon(Icons.tag),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState?.validate() ?? false) {
                                  await tagProvider.addTag(tagNameController.text);
                                  loadTags();
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text(
                "Create Tag +",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        content: Column(
          children: [
            // Search bar
            TextField(
              controller: searchController,
              onChanged: (_) => filterTags(),
              decoration: const InputDecoration(
                labelText: 'Search...',
              ),
            ),
            const SizedBox(height: 10),
            filteredTags.isEmpty
                ? const Text('No tags exist.\nTap + icon to create a new tag.')
                : SizedBox(
              height: 250,
              child: SingleChildScrollView(
                child: Column(
                  children: filteredTags.map((tag) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: Text(
                                  "# ${tag.name}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                                value: selectedTags
                                    .map((e) => e.id)
                                    .contains(tag.id),
                                onChanged: (isSelected) => updateTags(tag, isSelected!),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                await tagProvider.removeTag(tag.id);
                                loadTags();
                                setState(() { });
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: ()
            {
              print("Count of selected tags: ${selectedTags.length}");
              Navigator.of(context).pop(selectedTags);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
