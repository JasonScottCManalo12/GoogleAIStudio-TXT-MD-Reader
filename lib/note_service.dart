import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteItem {
  final String title;
  final String content;
  final String path;
  final DateTime lastModified;
  final bool isMarkdown;

  const NoteItem({
    required this.title,
    required this.content,
    required this.path,
    required this.lastModified,
    required this.isMarkdown,
  });

  String get displayTitle {
    final extension = isMarkdown ? '.md' : '.txt';
    return title.toLowerCase().endsWith(extension) ? title.substring(0, title.length - extension.length) : title;
  }
}

class NoteService {
  static const String _folderKey = 'selected_workspace_folder';
  static final RegExp _invalidFilenameCharacters = RegExp(r'[\\/:*?"<>|]');

  Future<String?> getSavedFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_folderKey);
    if (path == null || path.trim().isEmpty) return null;
    return path;
  }

  Future<String?> pickAndSaveDirectory() async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_folderKey, selectedDirectory);
    return selectedDirectory;
  }

  Future<List<NoteItem>> loadNotesFromDirectory(String folderPath) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final notes = <NoteItem>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final lowerPath = entity.path.toLowerCase();
      final isMarkdown = lowerPath.endsWith('.md');
      if (!isMarkdown && !lowerPath.endsWith('.txt')) continue;

      final content = await entity.readAsString();
      final stat = await entity.stat();
      final fileName = entity.uri.pathSegments.last;
      notes.add(NoteItem(title: fileName, content: content, path: entity.path, lastModified: stat.modified, isMarkdown: isMarkdown));
    }

    notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return notes;
  }

  String sanitizeTitle(String value) {
    var title = value.trim().replaceAll(_invalidFilenameCharacters, '-');
    title = title.replaceAll(RegExp(r'\s+'), ' ');
    title = title.replaceAll(RegExp(r'[. ]+$'), '');
    return title.isEmpty ? 'untitled' : title;
  }

  String fileNameFor({required String title, required bool isMarkdown}) {
    final cleanTitle = sanitizeTitle(title).replaceFirst(RegExp(r'\.(md|txt)$', caseSensitive: false), '');
    return '$cleanTitle.${isMarkdown ? 'md' : 'txt'}';
  }

  Future<File> saveNote({
    required String folderPath,
    required String title,
    required bool isMarkdown,
    required String content,
    String? previousPath,
  }) async {
    final fileName = fileNameFor(title: title, isMarkdown: isMarkdown);
    final filePath = '$folderPath${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    await file.writeAsString(content, flush: true);

    if (previousPath != null && previousPath != file.path) {
      final previousFile = File(previousPath);
      if (await previousFile.exists()) await previousFile.delete();
    }
    return file;
  }

  Future<void> deleteNote(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
