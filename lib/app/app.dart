import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

class ConvertixApp extends ConsumerWidget {
  final bool hasSeenOnboarding;

  const ConvertixApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Convertix',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: buildAppRouter(hasSeenOnboarding),
    );
  }
}
