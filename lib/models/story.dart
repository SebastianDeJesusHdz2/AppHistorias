import 'chapter.dart';
import 'race.dart';
import 'location.dart';

class Story {
  String id;
  String title;
  String description;
  String? imagePath;

  List<Chapter> chapters;
  List<Race> races;

  // NUEVO
  List<Location> locations;

  Story({
    required this.id,
    required this.title,
    required this.description,
    this.imagePath,
    List<Chapter>? chapters,
    List<Race>? races,
    List<Location>? locations,
  })  : chapters = chapters ?? <Chapter>[],
        races = races ?? <Race>[],
        locations = locations ?? <Location>[];

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'imagePath': imagePath,
    'chapters': chapters.map((c) => c.toMap()).toList(),
    'races': races.map((r) => r.toMap()).toList(),
    'locations': locations.map((l) => l.toMap()).toList(),
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
    locations: (m['locations'] as List? ?? [])
        .map((x) => Location.fromMap((x as Map).cast<String, dynamic>()))
        .toList(),
  );
}
