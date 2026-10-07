import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/home/home_shell.dart';

class GahwaApp extends StatelessWidget {
  const GahwaApp({super.key});

  bool get _webDesignPreview {
    if (!kIsWeb || !kDebugMode) return false;
    return Uri.base.queryParameters['preview'] == '1';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '가화만사성',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _webDesignPreview ? const HomeShell(preview: true) : const AuthGate(),
    );
  }
}
