import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gahwa_luck/core/theme/app_theme.dart';
import 'package:gahwa_luck/features/home/home_shell.dart';

void main() {
  testWidgets('home preview renders with drifting background', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final out = Platform.environment['HOME_CAPTURE'];
    if (out != null) {
      Future<void> load(String family, String path) async {
        final file = File(path);
        if (!file.existsSync()) return;
        final loader = FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
        await loader.load();
      }

      await tester.runAsync(() async {
        await load('Roboto', r'C:\Windows\Fonts\malgun.ttf');
        await load(
          'MaterialIcons',
          r'C:\Users\janny\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
        );
      });
    }

    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: RepaintBoundary(key: key, child: const HomeShell(preview: true)),
      ),
    ));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    if (out == null) return;
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
