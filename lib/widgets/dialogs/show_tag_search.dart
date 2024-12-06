
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/tag_model.dart';
import '../tags_selection_dialog.dart';

class ShowTagSearch extends StatefulWidget {
  final List<TagModel> selectedTags;
  const ShowTagSearch({super.key, required this.selectedTags});

  @override
  State<ShowTagSearch> createState() => _ShowTagSearchState();
}

class _ShowTagSearchState extends State<ShowTagSearch> {
  List<TagModel> selectedTags = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedTags = widget.selectedTags;
  }
  @override
  Widget build(BuildContext context) {
    var n = selectedTags.length;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        elevation: 0,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(Icons.tag,
                  color: Theme.of(context).colorScheme.primary, size: 22),
            ),
            selectedTags.isEmpty
                ? Expanded(
              child: GestureDetector(
                child: const Text(
                  'Tap to add a tag',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                onTap: () async {
                  selectedTags = await showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => TagsSelectionDialog(
                      selectedTags: selectedTags,
                    ),
                  );
                  if(selectedTags.length != n) {
                    print("Length: ${selectedTags.length}");
                    setState(() {});
                  }
                },
              ),
            )
                : Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    selectedTags.length,
                        (index) {
                      final tag = selectedTags.elementAt(index);

                      return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: FilterChip(
                            padding: const EdgeInsets.all(4.0),
                            label: Text('# ${tag.name}'),
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(20)),
                            onSelected: (selected) =>
                                setState(() => selectedTags.remove(tag)
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                selectedTags = await showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) => TagsSelectionDialog(
                    selectedTags: selectedTags,
                  ),
                );
                setState(() {});
              },
              icon: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
