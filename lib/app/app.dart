import 'package:flutter/material.dart';

import 'package:nesherprints/app/main_layout.dart';
import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';

class NesherPrintsApp extends StatelessWidget {
  const NesherPrintsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainLayout(),
    );
  }
}
