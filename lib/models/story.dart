// lib/models/story.dart
import 'race.dart';
import 'chapter.dart';

class Story {
  String id;
  String title;
  String description;
  String? imagePath;

  // Nuevo: capítulos
  List<Chapter> chapters;

  // Ya existente: razas
  List<Race> races;

  Story({
    required this.id,
    required this.title,
    required this.description,
    this.imagePath,
    List<Chapter>? chapters,
    List<Race>? races,
  })  : chapters = chapters ?? [],
        races = races ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'imagePath': imagePath,
    'chapters': chapters.map((c) => c.toMap()).toList(),
    'races': races.map((r) => r.toMap()).toList(),
  };

  factory Story.fromMap(Map<String, dynamic> m) => Story(
    id: m['id'] as String,
    title: m['title'] as String,
    description: (m['description'] ?? '') as String,
    imagePath: m['imagePath'] as String?,
    chapters: (m['chapters'] as List? ?? [])
        .map((x) => Chapter.fromMap((x as Map).cast<String, dynamic>()))
        .toList(),
    races: (m['races'] as List? ?? [])
        .map((x) => Race.fromMap((x as Map).cast<String, dynamic>()))
        .toList(),
  );
}
