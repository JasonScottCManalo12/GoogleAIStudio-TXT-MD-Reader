import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'editor_screen.dart';
import 'note_service.dart';

void main() {
  runApp(const NotepadApp());
}

class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.indigo;
    return MaterialApp(
      title: 'Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xfff7f8fc),
        inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0),
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
  final TextEditingController _searchController = TextEditingController();

  String? _currentFolderPath;
  List<NoteItem> _notes = [];
  bool _isLoading = true;
  Object? _loadError;
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _checkFolder();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkFolder() async {
    final path = await _noteService.getSavedFolderPath();
    if (!mounted) return;
    if (path != null) {
      _currentFolderPath = path;
    }
    await _refreshNotes(showLoader: true);
  }

  Future<void> _chooseFolder() async {
    final path = await _noteService.pickAndSaveDirectory();
    if (path == null || !mounted) return;
    setState(() {
      _currentFolderPath = path;
      _loadError = null;
    });
    await _refreshNotes(showLoader: true);
  }

  Future<void> _refreshNotes({bool showLoader = false}) async {
    if (_currentFolderPath == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) {
      setState(() {
        _isLoading = showLoader || _notes.isEmpty;
        _loadError = null;
      });
    }
    try {
      final notes = await _noteService.loadNotesFromDirectory(_currentFolderPath!);
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  List<NoteItem> get _visibleNotes {
    final query = _searchController.text.trim().toLowerCase();
    final notes = _notes.where((note) {
      return query.isEmpty || note.title.toLowerCase().contains(query) || note.content.toLowerCase().contains(query);
    }).toList();
    notes.sort((a, b) => _sortNewestFirst
        ? b.lastModified.compareTo(a.lastModified)
        : a.lastModified.compareTo(b.lastModified));
    return notes;
  }

  String _folderName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? path : parts.last;
  }

  Future<void> _openEditor([NoteItem? note]) async {
    if (_currentFolderPath == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(folderPath: _currentFolderPath!, note: note),
      ),
    );
    await _refreshNotes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleNotes = _visibleNotes;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notepad', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh notes',
            onPressed: _currentFolderPath == null ? null : () => _refreshNotes(showLoader: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<bool>(
            tooltip: 'Sort notes',
            initialValue: _sortNewestFirst,
            onSelected: (value) => setState(() => _sortNewestFirst = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text('Newest first')),
              PopupMenuItem(value: false, child: Text('Oldest first')),
            ],
            icon: const Icon(Icons.sort_rounded),
          ),
          IconButton(
            tooltip: 'Change folder',
            onPressed: _chooseFolder,
            icon: const Icon(Icons.folder_open_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentFolderPath == null
                ? _WelcomeView(onChooseFolder: _chooseFolder)
                : RefreshIndicator(
                    onRefresh: () => _refreshNotes(showLoader: false),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your workspace', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.folder_rounded, size: 17, color: theme.colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(_folderName(_currentFolderPath!), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                                    ),
                                    Text('${_notes.length} ${_notes.length == 1 ? 'note' : 'notes'}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _searchController,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'Search notes',
                                    prefixIcon: const Icon(Icons.search_rounded),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(icon: const Icon(Icons.clear_rounded), onPressed: _searchController.clear),
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_loadError != null)
                          SliverToBoxAdapter(child: _ErrorBanner(error: _loadError!, onRetry: () => _refreshNotes(showLoader: true)))
                        else if (_notes.isEmpty)
                          const SliverFillRemaining(hasScrollBody: false, child: _EmptyNotesView())
                        else if (visibleNotes.isEmpty)
                          const SliverFillRemaining(hasScrollBody: false, child: _NoResultsView())
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            sliver: SliverList.builder(
                              itemCount: visibleNotes.length,
                              itemBuilder: (_, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _NoteCard(note: visibleNotes[index], onTap: () => _openEditor(visibleNotes[index])),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: _currentFolderPath == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('New note'),
            ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = note.isMarkdown ? 'MD' : 'TXT';
    final preview = note.content.trim().replaceAll(RegExp(r'\s+'), ' ');
    return Card(
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(extension, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(preview.isEmpty ? 'No content yet' : preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 7),
                    Text(DateFormat('MMM d, yyyy · h:mm a').format(note.lastModified), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final VoidCallback onChooseFolder;
  const _WelcomeView({required this.onChooseFolder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded, size: 76, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('A calmer place for your notes', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('Choose a folder and keep your TXT and Markdown files organized in one simple workspace.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            FilledButton.icon(onPressed: onChooseFolder, icon: const Icon(Icons.folder_open_rounded), label: const Text('Choose a folder')),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotesView extends StatelessWidget {
  const _EmptyNotesView();
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.note_add_outlined, size: 56), const SizedBox(height: 14), Text('No notes here yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 6), const Text('Tap “New note” to create your first note.')])));
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No notes match your search.')));
}

class _ErrorBanner extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: Card(child: ListTile(leading: const Icon(Icons.error_outline_rounded), title: const Text('Could not load this folder'), subtitle: Text('$error', maxLines: 2, overflow: TextOverflow.ellipsis), trailing: TextButton(onPressed: onRetry, child: const Text('Retry')))));
}
