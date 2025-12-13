import 'place.dart';

class Location {
  String id;
  String name;
  String description;
  String? imagePath;

  // Sin fields/atributos
  List<Place> places;

  Location({
    required this.id,
    required this.name,
    required this.description,
    this.imagePath,
    List<Place>? places,
  }) : places = places ?? <Place>[];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'imagePath': imagePath,
    'places': places.map((p) => p.toMap()).toList(),
  };

  factory Location.fromMap(Map<String, dynamic> m) => Location(
    id: (m['id'] as String?) ?? '',
    name: (m['name'] as String?) ?? '',
    description: (m['description'] as String?) ?? '',
    imagePath: m['imagePath'] as String?,
    places: (m['places'] as List? ?? [])
        .map((x) => Place.fromMap((x as Map).cast<String, dynamic>()))
        .toList(),
  );
}
