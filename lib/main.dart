import 'package:flutter/material.dart';

import 'editor_screen.dart';
import 'note_service.dart';

void main() {
  runApp(const NotepadApp());
}

class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: const NotepadHomeScreen(),
    );
  }
}

class NotepadHomeScreen extends StatefulWidget {
  const NotepadHomeScreen({super.key});

  @override
  State<NotepadHomeScreen> createState() => _NotepadHomeScreenState();
}

class _NotepadHomeScreenState extends State<NotepadHomeScreen> {
  final NoteService _service = NoteService();
  bool _busy = false;

  Future<void> _openFile() async {
    setState(() => _busy = true);
    try {
      final document = await _service.openDocument();
      if (document != null && mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => EditorScreen(document: document)),
        );
      }
    } catch (error) {
      _showError('Could not open file', error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _newFile({required bool markdown}) async {
    final document = _service.newDocument(markdown: markdown);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => EditorScreen(document: document)),
    );
  }

  void _showError(String title, Object error) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('$error'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notepad', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Open file',
            onPressed: _busy ? null : _openFile,
            icon: const Icon(Icons.folder_open_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.description_outlined, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text('Simple text editing', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Create a document or open an existing .txt or .md file. Edit it, save it, or save a copy somewhere else.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _busy ? null : _openFile,
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.folder_open),
                  label: const Text('Open file'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _newFile(markdown: false),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('New text document'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _newFile(markdown: true),
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('New Markdown document'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
