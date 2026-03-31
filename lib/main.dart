import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'features/tasks/screens/task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar for edge-to-edge look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load persisted theme preference before the first frame
  final themeNotifier = await ThemeModeNotifier.load();

  runApp(FlodoApp(themeNotifier: themeNotifier));
}
