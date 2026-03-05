import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _kLoggedIn = 'auth_logged_in';
  static const _kCurrentUser = 'current_user';
  static const _kUsersJson = 'local_users_json';

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _loadUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(_kUsersJson);
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final out = <String, String>{};
        decoded.forEach((k, v) {
          if (k is String && v is String) out[k] = v;
        });
        return out;
      }
    } catch (_) {}

    return {};
  }

  Future<void> _saveUsers(SharedPreferences prefs, Map<String, String> users) async {
    await prefs.setString(_kUsersJson, jsonEncode(users));
  }

  Future<void> _login() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;

    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username and password")),
      );
      return;
    }

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);

    final ok = users.containsKey(u) && users[u] == p;

    if (!ok) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid login")),
      );
      return;
    }

    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kCurrentUser, u);

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  Future<void> _showRegisterDialog() async {
    final regUserCtrl = TextEditingController();
    final regPassCtrl = TextEditingController();
    bool regObscure = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Register"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: regUserCtrl,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: regPassCtrl,
                    obscureText: regObscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(regObscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => regObscure = !regObscure),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () async {
                    final u = regUserCtrl.text.trim();
                    final p = regPassCtrl.text;

                    if (u.isEmpty || p.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter username and password")),
                      );
                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final users = await _loadUsers(prefs);

                    if (users.containsKey(u)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Username already exists")),
                      );
                      return;
                    }

                    users[u] = p;
                    await _saveUsers(prefs, users);

                    _userCtrl.text = u;
                    _passCtrl.text = p;

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Registered! Now login")),
                    );

                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Register"),
                ),
              ],
            );
          },
        );
      },
    );

    // ✅ don’t dispose here (prevents the red crash)
    // regUserCtrl.dispose();
    // regPassCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  const Icon(Icons.lock, size: 50),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _loading ? null : _login,
                    icon: const Icon(Icons.login),
                    label: Text(_loading ? "Logging in..." : "Login"),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _showRegisterDialog,
                    child: const Text("Register (first time user)"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}