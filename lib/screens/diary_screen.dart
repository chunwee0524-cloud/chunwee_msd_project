import 'package:flutter/material.dart';
import '../data/diary_dao.dart';
import '../models/diary_entry.dart';
import '../widgets/diary_card.dart';
import '../widgets/empty_state.dart';
import 'add_entry_screen.dart';
import 'diary_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _dao = DiaryDao();
  List<DiaryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _dao.getAllEntries();
    if (!mounted) return;
    setState(() {
      _entries = data;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEntryScreen()),
    );
    if (saved == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved entry ✅")),
      );
    }
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete entry?"),
        content: const Text("This will remove the photo entry from your diary."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _delete(DiaryEntry entry) async {
    if (entry.id == null) return;
    await _dao.deleteEntry(entry.id!);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deleted entry")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? const EmptyState(
        icon: Icons.restaurant,
        title: "No meals recorded yet",
        subtitle: "Tap + to add your first meal photo.",
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: _entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final e = _entries[i];

            return Dismissible(
              key: ValueKey(e.id ?? e.createdAt),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.only(right: 16),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              onDismissed: (_) => _delete(e),
              child: DiaryCard(
                entry: e,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DiaryDetailScreen(entry: e)),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text("Add"),
      ),
    );
  }
}