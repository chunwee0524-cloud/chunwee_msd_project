import 'package:flutter/material.dart';
import '../data/bmi_dao.dart';
import '../models/bmi_log.dart';

class BmiHistoryScreen extends StatefulWidget {
  const BmiHistoryScreen({super.key});

  @override
  State<BmiHistoryScreen> createState() => _BmiHistoryScreenState();
}

class _BmiHistoryScreenState extends State<BmiHistoryScreen> {
  final _dao = BmiDao();

  List<BmiLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final data = await _dao.getAllLogs();
    if (!mounted) return;
    setState(() {
      _logs = data;
      _loading = false;
    });
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}";
  }

  String _bmiStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Future<bool> _confirmDeleteOne(BmiLog log) async {
    final owner = (log.name == null || log.name!.trim().isEmpty)
        ? "Unknown user"
        : log.name!.trim();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete this record?"),
        content: Text(
          "User: $owner\n"
              "BMI ${log.bmi.toStringAsFixed(1)} (${_bmiStatus(log.bmi)})\n"
              "${log.heightCm.toStringAsFixed(0)}cm • ${log.weightKg.toStringAsFixed(1)}kg\n\n"
              "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> _deleteOne(BmiLog log) async {
    if (log.id == null) return;

    final ok = await _confirmDeleteOne(log);
    if (!ok) return;

    await _dao.deleteLog(log.id!);
    await _loadAll();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Record deleted")),
    );
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear all history?"),
        content: const Text("This will delete all BMI records."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _dao.clearAll();
      await _loadAll();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All BMI history cleared")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[100],
      appBar: AppBar(
        title: const Text("BMI History"),
        actions: [
          IconButton(
            onPressed: _logs.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear all",
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text("No BMI records yet"))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final log = _logs[i];
          final owner = (log.name == null || log.name!.trim().isEmpty)
              ? "Unknown user"
              : log.name!.trim();

          final status = _bmiStatus(log.bmi);

          return Card(
            child: ListTile(
              title: Text(
                "BMI ${log.bmi.toStringAsFixed(1)} • "
                    "${log.heightCm.toStringAsFixed(0)}cm • "
                    "${log.weightKg.toStringAsFixed(1)}kg",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(log.createdAt)),
                  Text("User: $owner"),
                  Text("Status: $status"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteOne(log),
                tooltip: "Delete record",
              ),
            ),
          );
        },
      ),
    );
  }
}