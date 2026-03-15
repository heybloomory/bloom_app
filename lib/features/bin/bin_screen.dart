import 'package:flutter/material.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';

class BinScreen extends StatelessWidget {
  const BinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.dashboard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Bin',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Items in bin will be permanently deleted after 30 days.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Deleted Items Grid
            Expanded(
              child: GridView.builder(
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  return _BinItemCard(index: index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _BinItemCard extends StatelessWidget {
  final int index;

  const _BinItemCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Image Placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: Colors.grey.shade400,
                child: const Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
            ),
          ),

          // Action Overlay
          const Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Expanded(
                  child: _BinActionButton(
                    icon: Icons.restore,
                    label: 'Restore',
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: _BinActionButton(
                    icon: Icons.delete_forever,
                    label: 'Delete',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _BinActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BinActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
