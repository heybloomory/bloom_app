import 'package:flutter/material.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';

class ImageEditorScreen extends StatelessWidget {
  const ImageEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainAppShell(
      currentRoute: AppRoutes.dashboard,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Editor',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Center(child: Icon(Icons.image, size: 96)),
            ),
          ],
        ),
      ),
    );
  }
}
