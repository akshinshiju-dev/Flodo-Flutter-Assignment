import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/tasks/screens/task_list_screen.dart';

class FlodoApp extends StatelessWidget {
  final ThemeModeNotifier themeNotifier;
  const FlodoApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider<ThemeModeNotifier>.value(value: themeNotifier),
      ],
      child: Consumer<ThemeModeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            title: 'Flodo Tasks',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeNotifier.mode,
            home: const TaskListScreen(),
          );
        },
      ),
    );
  }
}
