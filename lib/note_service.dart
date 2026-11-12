import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteItem {
  final String title;
  final String content;
  final String path;
  final DateTime lastModified;
  final bool isMarkdown;

  NoteItem({
    required this.title,
    required this.content,
    required this.path,
    required this.lastModified,
    required this.isMarkdown,
  });
}

class NoteService {
  static const String _folderKey = 'selected_workspace_folder';

  Future<String?> getSavedFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_folderKey);
  }

  Future<String?> pickAndSaveDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_folderKey, selectedDirectory);
      return selectedDirectory;
    }
    return null;
  }

  Future<List<NoteItem>> loadNotesFromDirectory(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final entities = dir.listSync();
    List<NoteItem> notes = [];

    for (var entity in entities) {
      if (entity is File &&
          (entity.path.endsWith('.md') || entity.path.endsWith('.txt'))) {
        try {
          final content = await entity.readAsString();
          final stat = await entity.stat();
          final fileName = entity.uri.pathSegments.last;

          notes.add(
            NoteItem(
              title: fileName,
              content: content,
              path: entity.path,
              lastModified: stat.modified,
              isMarkdown: entity.path.endsWith('.md'),
            ),
          );
        } catch (_) {}
      }
    }

    notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return notes;
  }

  Future<File> saveNote({
    required String folderPath,
    required String fileName,
    required String content,
  }) async {
    final file = File('$folderPath/$fileName');
    return await file.writeAsString(content);
  }
}
