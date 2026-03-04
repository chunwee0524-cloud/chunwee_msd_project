import 'dart:io';
import 'package:flutter/material.dart';
import '../models/diary_entry.dart';

class DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const DiaryCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return "${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(entry.imagePath),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: cs.primary.withOpacity(0.08),
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported, color: cs.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.comment?.isNotEmpty == true ? entry.comment! : "No comment",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(entry.createdAt),
                      style: TextStyle(color: Colors.black.withOpacity(0.55)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.photo, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          "Meal photo",
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}