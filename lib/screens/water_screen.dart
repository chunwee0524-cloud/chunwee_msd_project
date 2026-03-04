import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  static const _kIntakeKey = 'water_intake_ml';
  static const _kGoalKey = 'water_goal_ml';

  int _intake = 0;
  int _goal = 2000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _intake = prefs.getInt(_kIntakeKey) ?? 0;
      _goal = prefs.getInt(_kGoalKey) ?? 2000;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kIntakeKey, _intake);
    await prefs.setInt(_kGoalKey, _goal);
  }

  Future<void> _add(int ml) async {
    setState(() => _intake += ml);
    await _save();
  }

  Future<void> _reset() async {
    setState(() => _intake = 0);
    await _save();
  }

  Future<void> _setGoalDialog() async {
    final controller = TextEditingController(text: _goal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set daily goal (ml)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "e.g. 2000"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              Navigator.pop(context, v);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != null && result >= 500 && result <= 6000) {
      setState(() => _goal = result);
      await _save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Goal set to $_goal ml")),
      );
    } else if (result != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a goal between 500 and 6000 ml")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final progress = (_goal == 0) ? 0.0 : (_intake / _goal).clamp(0.0, 1.0);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Water Intake", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text("Goal: $_goal ml", style: TextStyle(color: Colors.black.withOpacity(0.65))),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Text("$_intake / $_goal ml", style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _setGoalDialog,
                            icon: const Icon(Icons.flag),
                            label: const Text("Set goal"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Reset"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text("Quick add", style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _add(250),
                    child: const Text("+250 ml"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _add(500),
                    child: const Text("+500 ml"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () => _add(1000),
              child: const Text("+1000 ml"),
            ),

            const Spacer(),

            Center(
              child: Text(
                progress >= 1.0 ? "✅ Goal reached today!" : "Keep going 💧",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: progress >= 1.0
                      ? Colors.green
                      : Colors.black.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}