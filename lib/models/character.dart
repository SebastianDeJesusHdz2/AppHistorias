import 'package:uuid/uuid.dart';

class Character {
  String id;
  String name;
  String? description;
  String raceId;
  String? imagePath;

  /// Valores de los campos de la raza.
  /// Clave = `RaceFieldDef.key` de la raza.
  /// Valor = String / num / bool según el tipo.
  Map<String, dynamic> attributes;

  Character({
    String? id,
    required this.name,
    this.description,
    required this.raceId,
    this.imagePath,
    Map<String, dynamic>? attributes,
  })  : id = id ?? const Uuid().v4(),
        attributes = attributes ?? <String, dynamic>{};

  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      raceId: map['raceId'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      attributes: Map<String, dynamic>.from(
        map['attributes'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'raceId': raceId,
      'imagePath': imagePath,
      'attributes': attributes,
    };
  }
}
