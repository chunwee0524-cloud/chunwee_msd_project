import 'package:flutter/material.dart';
import '../data/calories_dao.dart';
import '../models/calories_day.dart';

class CaloriesHistoryScreen extends StatefulWidget {
  const CaloriesHistoryScreen({super.key});

  @override
  State<CaloriesHistoryScreen> createState() => _CaloriesHistoryScreenState();
}

class _CaloriesHistoryScreenState extends State<CaloriesHistoryScreen> {
  final _dao = CaloriesDao();

  bool _loading = true;
  List<CaloriesDay> _days = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _dao.getAllDays();
    if (!mounted) return;
    setState(() {
      _days = data;
      _loading = false;
    });
  }

  Future<void> _deleteOne(CaloriesDay day) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete this day?"),
        content: Text("This will remove calories record for ${day.day}."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (ok == true) {
      await _dao.deleteDay(day.day);
      await _load();
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear all history?"),
        content: const Text("This will delete all calories history."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Clear")),
        ],
      ),
    );

    if (ok == true) {
      await _dao.clearAll();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[100],
      appBar: AppBar(
        title: const Text("Calories History"),
        actions: [
          IconButton(
            onPressed: _days.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear all",
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _days.isEmpty
          ? const Center(child: Text("No calories history yet"))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _days.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final d = _days[i];
          return Card(
            child: ListTile(
              title: Text(
                d.day,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text("${d.totalCalories} kcal"),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteOne(d),
                tooltip: "Delete day",
              ),
            ),
          );
        },
      ),
    );
  }
}