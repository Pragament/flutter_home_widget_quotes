import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget_counter/models/tag_model.dart';

part 'quote_model.g.dart';

@HiveType(typeId: 0)
class QuoteModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String quote;

  @HiveField(2)
  List<TagModel> tags;

  QuoteModel({
    required this.id,
    required this.quote,
    required this.tags,
  });

  factory QuoteModel.fromMap(Map<String, dynamic> json) => QuoteModel(
    id: json['id'],
    quote: json['quote'],
    tags: (json['tags'] as List)
        .map((tag) => TagModel.fromMap(tag))
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'quote': quote,
    'tags': tags.map((tag) => tag.toMap()).toList(),
  };
}
