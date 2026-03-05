import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../models/food_item.dart';
import '../data/calories_dao.dart';
import 'calories_history_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  static const _kCurrentUser = 'current_user';

  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  // ✅ Today data
  int _todayTotal = 0;
  List<String> _todayItems = [];

  String _uid = 'default';

  final _calDao = CaloriesDao();

  final List<FoodItem> _items = const [
    FoodItem(name: 'Chicken Rice', category: 'Lunch', calories: 650),
    FoodItem(name: 'Nasi Lemak', category: 'Breakfast', calories: 700),
    FoodItem(name: 'Milk Shake', category: 'Snack', calories: 450),
    FoodItem(name: 'Banana', category: 'Snack', calories: 105),
    FoodItem(name: 'Oatmeal', category: 'Breakfast', calories: 250),
    FoodItem(name: 'Salad Bowl', category: 'Lunch', calories: 380),
    FoodItem(name: 'Grilled Fish + Rice', category: 'Dinner', calories: 520),
    FoodItem(name: 'Yogurt + Berries', category: 'Snack', calories: 220),
  ];

  List<String> get _categories => const ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _initUserAndLoadToday();
  }

  Future<void> _initUserAndLoadToday() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_kCurrentUser) ?? 'default';

    if (!mounted) return;
    setState(() => _uid = uid);

    await _loadToday();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _todayDayKey() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return "${now.year}-${two(now.month)}-${two(now.day)}";
  }

  // ✅ user-scoped today keys
  String get _todayKey => "cal_today__${_uid}__${_todayDayKey()}";
  String get _itemsKey => "${_todayKey}_items";

  // old (global) keys for migration
  String get _oldTodayKey => "cal_today_${_todayDayKey()}";
  String get _oldItemsKey => "${_oldTodayKey}_items";

  Future<void> _loadToday() async {
    final prefs = await SharedPreferences.getInstance();

    final scopedTotal = prefs.getInt(_todayKey);
    final scopedList = prefs.getStringList(_itemsKey);

    // fallback to old global keys if scoped does not exist yet
    final oldTotal = prefs.getInt(_oldTodayKey);
    final oldList = prefs.getStringList(_oldItemsKey);

    final total = scopedTotal ?? oldTotal ?? 0;
    final list = scopedList ?? oldList ?? <String>[];

    // migrate once
    if (scopedTotal == null && oldTotal != null) {
      await prefs.setInt(_todayKey, oldTotal);
    }
    if (scopedList == null && oldList != null) {
      await prefs.setStringList(_itemsKey, oldList);
    }

    if (!mounted) return;
    setState(() {
      _todayTotal = total;
      _todayItems = List<String>.from(list);
    });
  }

  Future<void> _saveTodayPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_todayKey, _todayTotal);
    await prefs.setStringList(_itemsKey, _todayItems);
  }

  List<FoodItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _items.where((x) {
      final matchesSearch = q.isEmpty || x.name.toLowerCase().contains(q);
      final matchesCat = _selectedCategory == 'All' || x.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  FoodItem? _findFoodByName(String name) {
    for (final f in _items) {
      if (f.name == name) return f;
    }
    return null;
  }

  Future<void> _addToToday(FoodItem item) async {
    await FirebaseAnalytics.instance.logEvent(
      name: "food_added",
      parameters: {
        "food_name": item.name,
        "calories": item.calories,
        "category": item.category,
        "user": _uid,
      },
    );

    setState(() {
      _todayTotal += item.calories;
      _todayItems.add(item.name);
    });

    await _saveTodayPrefs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added: ${item.name} (+${item.calories} kcal)")),
    );
  }

  Future<void> _removeFromToday(int index) async {
    final name = _todayItems[index];
    final food = _findFoodByName(name);
    final cal = food?.calories ?? 0;

    setState(() {
      _todayItems.removeAt(index);
      _todayTotal -= cal;
      if (_todayTotal < 0) _todayTotal = 0;
    });

    await _saveTodayPrefs();
  }

  Future<void> _resetToday() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset today?"),
        content: const Text("This will clear today’s food log and calories."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Reset")),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        _todayTotal = 0;
        _todayItems = [];
      });
      await _saveTodayPrefs();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Today reset ✅")),
      );
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaloriesHistoryScreen()),
    );
  }

  Future<void> _saveDayToHistory() async {
    if (_todayTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nothing to save yet")),
      );
      return;
    }

    final day = _todayDayKey();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Save today to history?"),
        content: Text("Date: $day\nTotal: $_todayTotal kcal\n\nThis will be stored in Calories History."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      ),
    );

    if (ok != true) return;

    // CaloriesDao should already be per-user if you updated it earlier.
    await _calDao.upsertDay(day, _todayTotal);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved $day ($_todayTotal kcal) ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: Colors.cyan[100],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today Calories", style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    "$_todayTotal kcal",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _todayItems.isEmpty ? null : _resetToday,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text("Reset"),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openHistory,
                        icon: const Icon(Icons.history),
                        label: const Text("History"),
                      ),
                      FilledButton.icon(
                        onPressed: _todayTotal <= 0 ? null : _saveDayToHistory,
                        icon: const Icon(Icons.save),
                        label: const Text("Save Day"),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text("${_todayItems.length} item(s)"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_todayItems.isEmpty)
                    const Text("No food added yet")
                  else
                    Column(
                      children: List.generate(_todayItems.length, (i) {
                        final name = _todayItems[i];
                        final food = _findFoodByName(name);
                        final cal = food?.calories ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text("$name • $cal kcal")),
                              IconButton(
                                onPressed: () => _removeFromToday(i),
                                icon: const Icon(Icons.close),
                                tooltip: "Remove",
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search food...',
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = _categories[i];
                final selected = c == _selectedCategory;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text("No results")),
            )
          else
            ...list.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text("${item.category} • ${item.calories} kcal"),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _addToToday(item),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}