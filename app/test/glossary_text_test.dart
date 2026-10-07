import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gahwa_luck/core/widgets/glossary_text.dart';

void main() {
  testWidgets('tapping an underlined term opens its meaning', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GlossaryText('오늘은 역마 기운이 있어 역마처럼 움직입니다.')),
    ));
    final rich = tester.widget<RichText>(find.byType(RichText).first);
    final root = rich.text as TextSpan;
    final underlined = <String>[];
    root.visitChildren((span) {
      if (span is TextSpan && span.style?.decoration == TextDecoration.underline) {
        underlined.add(span.text ?? '');
      }
      return true;
    });
    expect(underlined, ['역마']);

    await tester.tapOnText(find.textRange.ofSubstring('역마').first);
    await tester.pumpAndSettle();
    expect(find.text(glossaryTerms['역마']!), findsOneWidget);
  });
}
