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
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  bool _isMarkdown = false;
  bool _isPreviewMode = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _currentPath;
  Timer? _debounceTimer;

  final TextStyle _editorFont = const TextStyle(fontFamily: 'monospace', fontSize: 15, height: 1.5);

  @override
  void initState() {
    super.initState();
    _isMarkdown = widget.note?.isMarkdown ?? false;
    _currentPath = widget.note?.path;
    _titleController = TextEditingController(text: widget.note?.displayTitle ?? 'untitled');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() => _hasUnsavedChanges = true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), _saveNote);
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _hasUnsavedChanges = false;
    });
    try {
      final file = await _noteService.saveNote(
        folderPath: widget.folderPath,
        title: _titleController.text,
        isMarkdown: _isMarkdown,
        content: _contentController.text,
        previousPath: _currentPath,
      );
      if (!mounted) return;
      setState(() => _currentPath = file.path);
    } catch (error) {
      if (!mounted) return;
      setState(() => _hasUnsavedChanges = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save note: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges && !_isSaving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Save this note before leaving?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
          FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          TextButton(onPressed: () async { await _saveNote(); if (context.mounted) Navigator.pop(context, true); }, child: const Text('Save')),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _deleteNote() async {
    if (_currentPath == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('“${_titleController.text.trim().isEmpty ? 'untitled' : _titleController.text.trim()}” will be removed from this folder.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await _noteService.deleteNote(_currentPath!);
    if (mounted) Navigator.pop(context);
  }

  void _toggleMarkdown() {
    setState(() {
      _isMarkdown = !_isMarkdown;
      if (!_isMarkdown) _isPreviewMode = false;
      _hasUnsavedChanges = true;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), _saveNote);
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
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _confirmDiscardIfNeeded,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back_rounded), onPressed: () async { if (await _confirmDiscardIfNeeded() && mounted) Navigator.pop(context); }),
          title: TextField(
            controller: _titleController,
            textInputAction: TextInputAction.done,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            decoration: const InputDecoration(hintText: 'Note title'),
          ),
          actions: [
            if (_isSaving)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))))
            else
              Icon(_hasUnsavedChanges ? Icons.circle : Icons.cloud_done_outlined, size: 12, color: _hasUnsavedChanges ? theme.colorScheme.primary : theme.colorScheme.tertiary),
            IconButton(tooltip: 'Save now', onPressed: _isSaving ? null : _saveNote, icon: const Icon(Icons.save_outlined)),
            PopupMenuButton<String>(
              tooltip: 'More actions',
              onSelected: (value) { if (value == 'delete') _deleteNote(); },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'delete', enabled: _currentPath != null, child: const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.delete_outline_rounded), title: Text('Delete note'))),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  SegmentedButton<bool>(
                    segments: const [ButtonSegment(value: false, icon: Icon(Icons.edit_outlined), label: Text('Edit')), ButtonSegment(value: true, icon: Icon(Icons.visibility_outlined), label: Text('Preview'))],
                    selected: {_isPreviewMode},
                    onSelectionChanged: _isMarkdown ? (selection) => setState(() => _isPreviewMode = selection.first) : null,
                  ),
                  const Spacer(),
                  Text(_isMarkdown ? 'Markdown' : 'Plain text', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 6),
                  IconButton(tooltip: 'Switch file type', onPressed: _toggleMarkdown, icon: const Icon(Icons.swap_horiz_rounded)),
                ],
              ),
            ),
            Expanded(
              child: _isPreviewMode
                  ? Markdown(data: _contentController.text, padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), selectable: true, styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(p: _editorFont, code: _editorFont.copyWith(backgroundColor: theme.colorScheme.surfaceContainerHighest)))
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: TextField(
                        controller: _contentController,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        autofocus: widget.note == null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: _editorFont,
                        decoration: InputDecoration(hintText: 'Start writing…', hintStyle: _editorFont.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: .6)), filled: true, fillColor: theme.colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(18)),
                      ),
                    ),
            ),
            SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 10), child: Row(children: [Text('${_contentController.text.length} characters', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)), const SizedBox(width: 12), Text('${_contentController.text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length} words', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)), const Spacer(), Text(_hasUnsavedChanges ? 'Saving automatically…' : 'All changes saved', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))]))),
          ],
        ),
      ),
    );
  }
}
