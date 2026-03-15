import 'package:flutter/material.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';

class ImageEditorScreen extends StatelessWidget {
  const ImageEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.dashboard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image Editor',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: Center(child: Icon(Icons.image, size: 96)),
            ),
          ],
        ),
      ),
    );
  }
}
