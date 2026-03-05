import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../data/bmi_dao.dart';
import '../models/bmi_log.dart';
import 'bmi_history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _kNameBase = 'profile_name';
  static const _kHeightBase = 'profile_height_cm';
  static const _kWeightBase = 'profile_weight_kg';
  static const _kCurrentUser = 'current_user';

  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  final _bmiDao = BmiDao();

  bool _loading = true;
  String _uid = 'default';

  String _k(String base) => '${base}__$_uid';

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
    final uid = prefs.getString(_kCurrentUser) ?? 'default';

    final nameKey = '${_kNameBase}__$uid';
    final heightKey = '${_kHeightBase}__$uid';
    final weightKey = '${_kWeightBase}__$uid';

    final scopedName = prefs.getString(nameKey);
    final scopedHeight = prefs.getDouble(heightKey);
    final scopedWeight = prefs.getDouble(weightKey);

    final oldName = prefs.getString(_kNameBase);
    final oldHeight = prefs.getDouble(_kHeightBase);
    final oldWeight = prefs.getDouble(_kWeightBase);

    final name = scopedName ?? oldName ?? '';
    final height = scopedHeight ?? oldHeight ?? 0;
    final weight = scopedWeight ?? oldWeight ?? 0;

    // migrate once
    if (scopedName == null && oldName != null) await prefs.setString(nameKey, oldName);
    if (scopedHeight == null && oldHeight != null) await prefs.setDouble(heightKey, oldHeight);
    if (scopedWeight == null && oldWeight != null) await prefs.setDouble(weightKey, oldWeight);

    _nameCtrl.text = name;
    _heightCtrl.text = height == 0 ? '' : height.toStringAsFixed(0);
    _weightCtrl.text = weight == 0 ? '' : weight.toStringAsFixed(1);

    if (!mounted) return;
    setState(() {
      _uid = uid;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final name = _nameCtrl.text.trim();
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());

    // ✅ Simple validation so you "feel" it's working
    if (height == null || height <= 0 || weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid height and weight first.")),
      );
      return;
    }

    await prefs.setString(_k(_kNameBase), name);
    await prefs.setDouble(_k(_kHeightBase), height);
    await prefs.setDouble(_k(_kWeightBase), weight);

    await FirebaseAnalytics.instance.logEvent(
      name: 'profile_saved',
      parameters: {
        'user': _uid,
        'has_name': name.isNotEmpty ? 1 : 0,
        'has_height': ((height ?? 0) > 0) ? 1 : 0,
        'has_weight': ((weight ?? 0) > 0) ? 1 : 0,
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved ✅")),
    );
    setState(() {});
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
      name: nameNow.isEmpty ? null : nameNow,
      heightCm: h,
      weightKg: w,
      bmi: bmi,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _bmiDao.insertLog(log);

    await FirebaseAnalytics.instance.logEvent(
      name: 'bmi_record_saved',
      parameters: {
        'user': _uid,
        'height_cm': h.round(),
        'weight_kg': w,
        'bmi': double.parse(bmi.toStringAsFixed(1)),
        'status': _bmiCategory,
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved BMI record ✅")),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_logged_in', false);
    await prefs.remove(_kCurrentUser);

    await FirebaseAnalytics.instance.logEvent(name: 'logout');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final bmi = _bmi;
    final nameText = _nameCtrl.text.trim().isEmpty
        ? "Your Profile"
        : "${_nameCtrl.text.trim()}'s Profile";

    return Scaffold(
      backgroundColor: Colors.cyan[100],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: "Name"),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Height (cm)"),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Weight (kg)"),
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
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
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
                        Text(_bmiCategory, style: TextStyle(color: Colors.black.withOpacity(0.65))),
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