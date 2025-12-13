class Place {
  String id;
  String name;
  String? description;
  String locationId;
  String? imagePath;

  // Sin attributes

  Place({
    required this.id,
    required this.name,
    this.description,
    required this.locationId,
    this.imagePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'locationId': locationId,
    'imagePath': imagePath,
  };

  factory Place.fromMap(Map<String, dynamic> m) => Place(
    id: (m['id'] as String?) ?? '',
    name: (m['name'] as String?) ?? '',
    description: m['description'] as String?,
    locationId: (m['locationId'] as String?) ?? '',
    imagePath: m['imagePath'] as String?,
  );
}
