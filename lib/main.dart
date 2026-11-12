import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'note_service.dart';
import 'editor_screen.dart';

void main() => runApp(const NotepadApp());

class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFBFBFB),
        appBarTheme: const AppBarTheme(elevation: 0.5, backgroundColor: Color(0xFFF7F7F7)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(elevation: 0.5, backgroundColor: Color(0xFF252526)),
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
  final NoteService _noteService = NoteService();
  String? _currentFolderPath;
  List<NoteItem> _notes = [];
  bool _isLoading = true;
  final TextStyle _mono = const TextStyle(fontFamily: 'monospace');

  @override
  void initState() {
    super.initState();
    _checkFolder();
  }

  Future<void> _checkFolder() async {
    setState(() => _isLoading = true);
    final path = await _noteService.getSavedFolderPath();
    if (path != null) {
      _currentFolderPath = path;
      _notes = await _noteService.loadNotesFromDirectory(path);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _chooseFolder() async {
    final path = await _noteService.pickAndSaveDirectory();
    if (path != null) {
      setState(() => _currentFolderPath = path);
      _refreshNotes();
    }
  }

  Future<void> _refreshNotes() async {
    if (_currentFolderPath == null) return;
    setState(() => _isLoading = true);
    final notes = await _noteService.loadNotesFromDirectory(_currentFolderPath!);
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notepad', style: _mono.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_currentFolderPath != null)
              Text(
                _currentFolderPath!.split('/').last,
                style: _mono.copyWith(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Change Folder',
            onPressed: _chooseFolder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentFolderPath == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Select a folder to start', style: _mono),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _chooseFolder,
                        icon: const Icon(Icons.folder_open),
                        label: Text('Select Folder', style: _mono),
                      ),
                    ],
                  ),
                )
              : _notes.isEmpty
                  ? Center(child: Text('Folder is empty.\nTap + to write a note.', textAlign: TextAlign.center, style: _mono))
                  : ListView.separated(
                      itemCount: _notes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return ListTile(
                          title: Text(note.title, style: _mono.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${DateFormat('yyyy-MM-dd HH:mm').format(note.lastModified)}  ${note.content.split('\n').first}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _mono.copyWith(fontSize: 12),
                          ),
                          trailing: Text(
                            note.isMarkdown ? '.md' : '.txt',
                            style: _mono.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditorScreen(folderPath: _currentFolderPath!, note: note),
                              ),
                            );
                            _refreshNotes();
                          },
                        );
                      },
                    ),
      floatingActionButton: _currentFolderPath == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditorScreen(folderPath: _currentFolderPath!)),
                );
                _refreshNotes();
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
