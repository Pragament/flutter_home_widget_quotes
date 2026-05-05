// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// ************************************************************************** 
// TypeAdapterGenerator
// **************************************************************************

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 2;

  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final rawScheduleTime = fields[7] as String?;
    final fallbackScheduleTime = fields[5] as String?;
    return Todo(
      title: fields[0] as String,
      description: fields[1] as String,
      category: fields[2] as String,
      tags: (fields[3] as List).cast<String>(),
      isCompleted: (fields[4] as bool?) ?? false,
      scheduledTime: fields[5] as String?,
      isRecurring: (fields[6] as bool?) ?? false,
      scheduleTime: _parseTimeOfDay(rawScheduleTime ?? fallbackScheduleTime),
      repeatType: (fields[8] as String?) ?? 'daily',
      lastCompletedDate: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    final scheduleTimeValue =
        _formatTimeOfDay(obj.scheduleTime) ?? obj.scheduledTime;
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.scheduledTime)
      ..writeByte(6)
      ..write(obj.isRecurring)
      ..writeByte(7)
      ..write(scheduleTimeValue)
      ..writeByte(8)
      ..write(obj.repeatType)
      ..writeByte(9)
      ..write(obj.lastCompletedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

TimeOfDay? _parseTimeOfDay(String? value) {
  if (value == null || !value.contains(':')) {
    return null;
  }
  final parts = value.split(':');
  if (parts.length != 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

String? _formatTimeOfDay(TimeOfDay? time) {
  if (time == null) {
    return null;
  }
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
