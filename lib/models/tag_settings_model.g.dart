// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagSettingsModelAdapter extends TypeAdapter<TagSettingsModel> {
  @override
  final int typeId = 3;

  @override
  TagSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TagSettingsModel(
      tagName: fields[0] as String,
      scheduledTime: fields[1] as String?,
      notificationEnabled: fields[2] as bool,
      wallpaperEnabled: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TagSettingsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.tagName)
      ..writeByte(1)
      ..write(obj.scheduledTime)
      ..writeByte(2)
      ..write(obj.notificationEnabled)
      ..writeByte(3)
      ..write(obj.wallpaperEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
