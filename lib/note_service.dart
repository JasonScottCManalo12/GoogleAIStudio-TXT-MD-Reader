import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class TextDocument {
  final String name;
  final String content;
  final String? path;

  const TextDocument({required this.name, required this.content, this.path});

  bool get isMarkdown => name.toLowerCase().endsWith('.md');
}

class NoteService {
  Future<TextDocument?> openDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'md'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final selected = result.files.single;
    final bytes = selected.bytes;
    if (bytes == null) {
      throw const FormatException('The selected file could not be read.');
    }
    return TextDocument(
      name: selected.name,
      content: utf8.decode(bytes, allowMalformed: true),
      path: Platform.isAndroid ? null : selected.path,
    );
  }

  TextDocument newDocument({bool markdown = false}) {
    return TextDocument(
      name: markdown ? 'Untitled.md' : 'Untitled.txt',
      content: '',
    );
  }

  Future<TextDocument?> save(TextDocument document, String content) async {
    final path = document.path;
    if (path == null || path.trim().isEmpty) {
      return saveAs(document, content);
    }
    final file = File(path);
    await file.writeAsString(content, encoding: utf8, flush: true);
    return TextDocument(name: document.name, content: content, path: path);
  }

  Future<TextDocument?> saveAs(TextDocument document, String content) async {
    final suggestedName = _ensureSupportedExtension(document.name);
    final bytes = Uint8List.fromList(utf8.encode(content));
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save text document',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: const ['txt', 'md'],
      bytes: bytes,
    );
    if (savedPath == null) return null;

    final savedName = Platform.isAndroid\n        ? suggestedName\n        : savedPath.replaceAll('\\', '/').split('/').last;
    return TextDocument(
      name: _ensureSupportedExtension(savedName),
      content: content,
      path: Platform.isAndroid ? null : savedPath,
    );
  }

  String _ensureSupportedExtension(String name) {
    final trimmed = name.trim().isEmpty ? 'Untitled.txt' : name.trim();
    final lower = trimmed.toLowerCase();
    if (lower.endsWith('.txt') || lower.endsWith('.md')) return trimmed;
    return '$trimmed.txt';
  }
}
