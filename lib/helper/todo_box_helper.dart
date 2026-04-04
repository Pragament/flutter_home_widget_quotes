import 'package:hive/hive.dart';

import '../models/todo_model.dart';

class TodoBoxHelper {
  static Future<Box<Todo>> getTodoBox() async {
    if (Hive.isBoxOpen('todos')) {
      return Hive.box<Todo>('todos');
    }
    return Hive.openBox<Todo>('todos');
  }
}
