import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'note_service.dart';

class EditorScreen extends StatefulWidget {
  final TextDocument document;

  const EditorScreen({super.key, required this.document});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final NoteService _service = NoteService();
  late TextDocument _document;
  late final TextEditingController _contentController;
  bool _dirty = false;
  bool _saving = false;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _contentController = TextEditingController(text: _document.content)
      ..addListener(_handleEdit);
  }

  void _handleEdit() {
    setState(() => _dirty = true);
  }

  Future<bool> _save({bool saveAs = false}) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      final result = saveAs
          ? await _service.saveAs(_document, _contentController.text)
          : await _service.save(_document, _contentController.text);
      if (result == null) return false;
      setState(() {
        _document = result;
        _dirty = false;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      final action = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Could not save this file'),
          content: Text('$error\n\nSave a new copy instead?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save As')),
          ],
        ),
      );
      if (action == true && mounted) {\n        setState(() => _saving = false);\n        return _save(saveAs: true);\n      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: Text('Save changes to ${_document.name} before closing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'discard'), child: const Text('Discard')),
          TextButton(onPressed: () => Navigator.pop(context, 'stay'), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
        ],
      ),
    );
    if (choice == 'discard') return true;
    if (choice == 'save') return _save();
    return false;
  }

  @override
  void dispose() {
    _contentController
      ..removeListener(_handleEdit)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMarkdown = _document.isMarkdown;
    return WillPopScope(
      onWillPop: _confirmLeave,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close document',
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmLeave() && mounted) Navigator.pop(context);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_document.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(_dirty ? 'Unsaved changes' : 'Saved', style: theme.textTheme.labelSmall),
            ],
          ),
          actions: [
            if (isMarkdown)
              IconButton(
                tooltip: _preview ? 'Edit Markdown' : 'Preview Markdown',
                onPressed: () => setState(() => _preview = !_preview),
                icon: Icon(_preview ? Icons.edit_outlined : Icons.visibility_outlined),
              ),
            IconButton(
              tooltip: 'Save As',
              onPressed: _saving ? null : () => _save(saveAs: true),
              icon: const Icon(Icons.save_as_outlined),
            ),
            IconButton(
              tooltip: 'Save',
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: _preview && isMarkdown
            ? Markdown(data: _contentController.text, selectable: true, padding: const EdgeInsets.all(20))
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _contentController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  autofocus: true,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 15, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Start typing…',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${_contentController.text.length} characters', style: theme.textTheme.labelSmall),
                const Spacer(),
                Text(isMarkdown ? 'Markdown' : 'Plain text', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
