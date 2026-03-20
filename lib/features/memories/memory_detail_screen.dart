import 'package:flutter/material.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';

class MemoryDetailScreen extends StatelessWidget {
  const MemoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.dashboard,
      child: Column(
        children: [
          // Media Area
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade400,
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 96,
                  color: Colors.white70,
                ),
              ),
            ),
          ),

          // Details & Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memory Title',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This is a beautiful moment captured during the event.',
                  style: TextStyle(color: Colors.grey),
                ),

                SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ActionButton(icon: Icons.favorite_border, label: 'Like'),
                    _ActionButton(icon: Icons.share, label: 'Share'),
                    _ActionButton(icon: Icons.delete_outline, label: 'Delete'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
