import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'note_service.dart';

class EditorScreen extends StatefulWidget {
  final String folderPath;
  final NoteItem? note;

  const EditorScreen({super.key, required this.folderPath, this.note});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final NoteService _noteService = NoteService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  bool _isMarkdown = false;
  bool _isPreviewMode = false;
  Timer? _debounceTimer;

  final TextStyle _notepadFont = const TextStyle(
    fontFamily: 'monospace',
    fontSize: 15,
    height: 1.4,
  );

  @override
  void initState() {
    super.initState();
    _isMarkdown = widget.note?.isMarkdown ?? false;
    _titleController = TextEditingController(
      text: widget.note != null
          ? widget.note!.title.replaceAll(RegExp(r'\.(md|txt)$'), '')
          : 'untitled',
    );
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    _contentController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _saveNote);
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim().isEmpty ? 'untitled' : _titleController.text.trim();
    final ext = _isMarkdown ? '.md' : '.txt';
    final fileName = '$title$ext';

    await _noteService.saveNote(
      folderPath: widget.folderPath,
      fileName: fileName,
      content: _contentController.text,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _titleController,
          style: _notepadFont.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'filename'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isMarkdown = !_isMarkdown;
                if (!_isMarkdown) _isPreviewMode = false;
              });
              _saveNote();
            },
            child: Text(_isMarkdown ? '.md' : '.txt', style: _notepadFont.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (_isMarkdown)
            IconButton(
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility_outlined),
              onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
            ),
        ],
      ),
      body: _isPreviewMode
          ? Markdown(
              data: _contentController.text,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: _notepadFont,
                code: _notepadFont.copyWith(backgroundColor: Colors.black12),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                autofocus: widget.note == null,
                style: _notepadFont,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your notes here...',
                  hintStyle: _notepadFont.copyWith(color: Colors.grey),
                ),
              ),
            ),
    );
  }
}
