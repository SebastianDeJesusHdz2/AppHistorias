// lib/models/race.dart
import 'character.dart';

class Race {
  String id;
  String name;
  String description;
  String? imagePath;
  List<RaceFieldDef> fields; // si las usas
  List<Character> characters;

  Race({
    required this.id,
    required this.name,
    required this.description,
    this.imagePath,
    List<RaceFieldDef>? fields,
    List<Character>? characters,
  })  : fields = fields ?? [],
        characters = characters ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'imagePath': imagePath,
    'fields': fields.map((f) => f.toMap()).toList(),
    'characters': characters.map((c) => c.toMap()).toList(),
  };

  factory Race.fromMap(Map<String, dynamic> m) => Race(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String,
    imagePath: m['imagePath'] as String?,
    fields: (m['fields'] as List? ?? [])
        .map((x) => RaceFieldDef.fromMap((x as Map).cast<String, dynamic>()))
        .toList(),
    characters: (m['characters'] as List? ?? [])
        .map((x) => Character.fromMap((x as Map).cast<String, dynamic>()))
        .toList(),
  );
}

// Define lo mínimo para RaceFieldDef si lo usas
enum RaceFieldType { text, number, boolean }

class RaceFieldDef {
  String key;
  String label;
  RaceFieldType type;

  RaceFieldDef({required this.key, required this.label, required this.type});

  Map<String, dynamic> toMap() =>
      {'key': key, 'label': label, 'type': type.name};

  factory RaceFieldDef.fromMap(Map<String, dynamic> m) => RaceFieldDef(
    key: m['key'] as String,
    label: m['label'] as String,
    type: RaceFieldType.values.firstWhere(
          (t) => t.name == (m['type'] as String? ?? 'text'),
      orElse: () => RaceFieldType.text,
    ),
  );
}

