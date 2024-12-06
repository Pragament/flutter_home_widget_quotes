import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/tag_model.dart';

class TagProvider with ChangeNotifier {
  List<TagModel> _tags = [];

  List<TagModel> get tags => _tags;

  TagProvider() {
    _loadTags();
  }

  // Load tags from Hive into _tags
  Future<void> _loadTags() async {
    final box = Hive.box<TagModel>('tagsBox');
    _tags = box.values.toList();
    notifyListeners();
  }

  // Add a new tag to Hive and update the provider state
  Future<void> addTag(String name) async {
    final box = Hive.box<TagModel>('tagsBox');
    final newTag = TagModel(
      id: const Uuid().v4(), // Generate a unique ID
      name: name,
    );
    await box.add(newTag);
    _tags.add(newTag);
    notifyListeners();
  }

  // Remove a tag by ID
  Future<void> removeTag(String tagId) async {
    final box = Hive.box<TagModel>('tagsBox');
    final index = _tags.indexWhere((tag) => tag.id == tagId);
    if (index != -1) {
      await box.deleteAt(index);
      _tags.removeAt(index);
      notifyListeners();
    }
  }

  // Update a tag's name
  Future<void> updateTag(String tagId, String newName) async {
    final box = Hive.box<TagModel>('tagsBox');
    final index = _tags.indexWhere((tag) => tag.id == tagId);
    if (index != -1) {
      final updatedTag = _tags[index];
      updatedTag.name = newName;
      await box.putAt(index, updatedTag);
      _tags[index] = updatedTag;
      notifyListeners();
    }
  }

}
