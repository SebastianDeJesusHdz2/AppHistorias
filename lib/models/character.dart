// lib/models/character.dart
class Character {
  String id;
  String name;

  // Campos opcionales básicos
  String? description;
  String? imagePath;
  String? raceId;

  // NUEVOS: para coincidir con CharacterForm
  String? physicalTraits;
  String? personality;
  Map<String, dynamic> customFields;

  Character({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.raceId,
    this.physicalTraits,
    this.personality,
    Map<String, dynamic>? customFields,
  }) : customFields = customFields ?? {};

  // Serialización a Map (apta para guardar como JSON en Hive)
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'imagePath': imagePath,
    'raceId': raceId,
    'physicalTraits': physicalTraits,
    'personality': personality,
    'customFields': customFields,
  };

  // Deserialización desde Map
  factory Character.fromMap(Map<String, dynamic> m) => Character(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String?,
    imagePath: m['imagePath'] as String?,
    raceId: m['raceId'] as String?,
    physicalTraits: m['physicalTraits'] as String?,
    personality: m['personality'] as String?,
    customFields: (m['customFields'] as Map?)?.cast<String, dynamic>() ?? {},
  );

  // (Opcional) utilidad para ediciones
  Character copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    String? raceId,
    String? physicalTraits,
    String? personality,
    Map<String, dynamic>? customFields,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      raceId: raceId ?? this.raceId,
      physicalTraits: physicalTraits ?? this.physicalTraits,
      personality: personality ?? this.personality,
      customFields: customFields ?? Map<String, dynamic>.from(this.customFields),
    );
  }
}

