// lib/models/chapter.dart
class Chapter {
  String id;
  String title;
  String content;

  Chapter({required this.id, required this.title, required this.content});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
  };

  factory Chapter.fromMap(Map<String, dynamic> m) =>
      Chapter(id: m['id'], title: m['title'], content: m['content'] ?? '');
}

