import 'package:flutter/material.dart';
import '../../layout/main_app_shell.dart';

class MemoryListingScreen extends StatelessWidget {
  const MemoryListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Memories',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All memories from this album',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Memory Grid
            Expanded(
              child: GridView.builder(
                itemCount: 24,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  return _MemoryGridCard(index: index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _MemoryGridCard extends StatelessWidget {
  final int index;

  const _MemoryGridCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // Navigate to MemoryDetailPage later
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.grey.shade400,
                  child: const Icon(
                    Icons.photo,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Memory ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
