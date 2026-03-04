import 'dart:io';

import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import '../data/diary_dao.dart';
import '../services/image_service.dart';

class AddEntryScreen extends StatefulWidget {
  final String? initialComment;

  const AddEntryScreen({super.key, this.initialComment});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _commentController = TextEditingController();

  final _imageService = ImageService();
  final _dao = DiaryDao();

  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.initialComment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final file = await _imageService.takeAndSavePhoto();
    final path = file?.path;

    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No photo taken")),
      );
      return;
    }

    setState(() => _imagePath = path);
  }

  Future<void> _saveEntry() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please take a photo first")),
      );
      return;
    }

    setState(() => _saving = true);

    final entry = DiaryEntry(
      imagePath: _imagePath!,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _dao.insertEntry(entry);

    if (!mounted) return;
    setState(() => _saving = false);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Entry"),
      ),
      backgroundColor: Colors.deepPurple,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imagePath == null
                          ? Container(
                        alignment: Alignment.center,
                        color: Colors.black.withOpacity(0.04),
                        child: const Text("No photo yet"),
                      )
                          : Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _saving ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Photo"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Comment (optional)",
                  hintText: "e.g., Chicken rice (650 kcal)",
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: _saving ? null : _saveEntry,
            icon: _saving
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save),
            label: Text(_saving ? "Saving..." : "Save Entry"),
          ),
        ],
      ),
    );
  }
}