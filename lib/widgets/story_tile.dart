import 'dart:io';
import 'package:flutter/material.dart';
import '../models/story.dart';

class StoryTile extends StatelessWidget {
  final Story story;
  final VoidCallback? onTap;

  StoryTile({required this.story, this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;
    if (story.imagePath != null && story.imagePath!.isNotEmpty) {
      leadingWidget = Image.file(
        File(story.imagePath!),
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.book, size: 38),
      );
    } else {
      leadingWidget = Icon(Icons.book, size: 38);
    }

    return ListTile(
      leading: leadingWidget,
      title: Text(story.title),
      subtitle: Text(story.description),
      onTap: onTap,
    );
  }
}


