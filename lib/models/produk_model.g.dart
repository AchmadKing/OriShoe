// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'produk_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProdukModelAdapter extends TypeAdapter<ProdukModel> {
  @override
  final int typeId = 0;

  @override
  ProdukModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProdukModel(
      nama: fields[0] as String,
      harga: fields[1] as double,
      tipe: fields[2] as String,
      size: (fields[3] as List).cast<String>(),
      imagePath: fields[4] as String,
      deskripsi: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProdukModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nama)
      ..writeByte(1)
      ..write(obj.harga)
      ..writeByte(2)
      ..write(obj.tipe)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.deskripsi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProdukModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
