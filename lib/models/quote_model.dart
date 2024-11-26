import 'package:hive_flutter/hive_flutter.dart';

part 'quote_model.g.dart';

@HiveType(typeId: 0)
class QuoteModel {
  @HiveField(0)
  String id;
  @HiveField(1)
  String quote;

  QuoteModel({
    required this.id,
    required this.quote,
  });

  factory QuoteModel.fromMap(Map<String, dynamic> json) => QuoteModel(
    id: json["id"],
    quote: json["quote"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "quote": quote,
  };
}