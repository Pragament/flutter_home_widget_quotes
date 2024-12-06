import 'package:hive_flutter/hive_flutter.dart';

part 'tag_model.g.dart';

@HiveType(typeId: 1)
class TagModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  TagModel({
    required this.id,
    required this.name,
  });

  factory TagModel.fromMap(Map<String, dynamic> json) => TagModel(
    id: json['id'],
    name: json['name'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
  };
}