import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bmi_dao.dart';
import '../models/bmi_log.dart';
import 'bmi_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _kName = 'profile_name';
  static const _kHeight = 'profile_height_cm';
  static const _kWeight = 'profile_weight_kg';

  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  final _bmiDao = BmiDao();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _nameCtrl.text = prefs.getString(_kName) ?? '';
    _heightCtrl.text = (prefs.getDouble(_kHeight) ?? 0).toStringAsFixed(0);
    _weightCtrl.text = (prefs.getDouble(_kWeight) ?? 0).toStringAsFixed(1);

    // If saved values were 0, clear display
    if ((prefs.getDouble(_kHeight) ?? 0) == 0) _heightCtrl.text = '';
    if ((prefs.getDouble(_kWeight) ?? 0) == 0) _weightCtrl.text = '';

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final name = _nameCtrl.text.trim();
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());

    await prefs.setString(_kName, name);
    await prefs.setDouble(_kHeight, height ?? 0);
    await prefs.setDouble(_kWeight, weight ?? 0);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved ✅")),
    );
    setState(() {}); // refresh BMI display
  }

  double? get _heightCm {
    final v = double.tryParse(_heightCtrl.text.trim());
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _weightKg {
    final v = double.tryParse(_weightCtrl.text.trim());
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _bmi {
    final h = _heightCm;
    final w = _weightKg;
    if (h == null || w == null) return null;

    final hm = h / 100.0;
    return w / (hm * hm);
  }

  String get _bmiCategory {
    final bmi = _bmi;
    if (bmi == null) return '-';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Future<void> _saveBmiRecord() async {
    final h = _heightCm;
    final w = _weightKg;
    final bmi = _bmi;

    if (h == null || w == null || bmi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid height and weight first.")),
      );
      return;
    }

    final nameNow = _nameCtrl.text.trim();
    final log = BmiLog(
      name: nameNow.isEmpty ? null : nameNow, // ✅ save owner name
      heightCm: h,
      weightKg: w,
      bmi: bmi,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _bmiDao.insertLog(log);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved BMI record ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final bmi = _bmi;
    final nameText =
    _nameCtrl.text.trim().isEmpty ? "Your Profile" : "${_nameCtrl.text.trim()}'s Profile";

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      hintText: "e.g., Caleb",
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Height (cm)",
                            hintText: "e.g., 170",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Weight (kg)",
                            hintText: "e.g., 63.0",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Profile"),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: _saveBmiRecord,
                    icon: const Icon(Icons.add_chart),
                    label: const Text("Save BMI record"),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BmiHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text("View BMI history"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("BMI", style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          bmi == null ? "-" : bmi.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bmiCategory,
                          style: TextStyle(color: Colors.black.withOpacity(0.65)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.monitor_weight, size: 34),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}