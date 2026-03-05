import 'dart:io';
import 'package:flutter/material.dart';
import '../models/diary_entry.dart';

class DiaryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.cyan[100],
      appBar: AppBar(title: const Text("Entry")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              File(entry.imagePath),
              height: 320,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 320,
                color: cs.primary.withOpacity(0.08),
                alignment: Alignment.center,
                child: Icon(Icons.image_not_supported, size: 42, color: cs.primary),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            entry.comment?.isNotEmpty == true ? entry.comment! : "No comment",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(entry.createdAt),
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}