import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  // Base keys (we will scope them by user)
  static const _kIntakeBase = 'water_intake_ml';
  static const _kGoalBase = 'water_goal_ml';
  static const _kCurrentUser = 'current_user';

  int _intake = 0;
  int _goal = 2000;
  bool _loading = true;

  String _uid = 'default';

  String _k(String base) => '${base}__$_uid';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_kCurrentUser) ?? 'default';

    // Migration fallback (if old global keys exist)
    final scopedIntake = prefs.getInt('${_kIntakeBase}__$uid');
    final scopedGoal = prefs.getInt('${_kGoalBase}__$uid');

    final oldIntake = prefs.getInt(_kIntakeBase);
    final oldGoal = prefs.getInt(_kGoalBase);

    final intake = scopedIntake ?? oldIntake ?? 0;
    final goal = scopedGoal ?? oldGoal ?? 2000;

    // If we loaded from old keys, write into new scoped keys once
    if (scopedIntake == null && oldIntake != null) {
      await prefs.setInt('${_kIntakeBase}__$uid', oldIntake);
    }
    if (scopedGoal == null && oldGoal != null) {
      await prefs.setInt('${_kGoalBase}__$uid', oldGoal);
    }

    if (!mounted) return;
    setState(() {
      _uid = uid;
      _intake = intake;
      _goal = goal;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_k(_kIntakeBase), _intake);
    await prefs.setInt(_k(_kGoalBase), _goal);
  }

  Future<void> _add(int ml) async {
    await FirebaseAnalytics.instance.logEvent(
      name: "water_added",
      parameters: {
        "amount_ml": ml,
        "current_intake": _intake + ml,
        "goal_ml": _goal,
        "user": _uid,
      },
    );

    setState(() => _intake += ml);
    await _save();
  }

  Future<void> _reset() async {
    setState(() => _intake = 0);
    await _save();
  }

  Future<void> _setGoalDialog() async {
    String value = _goal.toString();

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Set daily goal (ml)"),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "e.g. 2000",
            ),
            onChanged: (v) {
              value = v;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(value.trim());
                Navigator.pop(dialogContext, v);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != null && result >= 500 && result <= 6000) {
      setState(() {
        _goal = result;
      });

      await _save();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Goal set to $_goal ml")),
      );
    } else if (result != null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a goal between 500 and 6000 ml"),
        ),
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
      backgroundColor: Colors.cyan[100],
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
                  color: progress >= 1.0 ? Colors.green : Colors.black.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}