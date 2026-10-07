import 'dart:convert';

import 'package:flutter/services.dart';

class HanjaChoice {
  const HanjaChoice(this.character, this.meaning);

  final String character;
  final String meaning;
}

class HanjaCatalog {
  const HanjaCatalog(this.bySyllable);

  final Map<String, List<HanjaChoice>> bySyllable;

  static HanjaCatalog? _cached;

  static Future<HanjaCatalog> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/name_hanja.json');
    final catalog = parse(raw);
    _cached = catalog;
    return catalog;
  }

  static HanjaCatalog parse(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final bySyllable = <String, List<HanjaChoice>>{};
    for (final entry in decoded.entries) {
      final rows = entry.value as List<dynamic>;
      bySyllable[entry.key] = [
        for (final row in rows)
          HanjaChoice(
            (row as List<dynamic>)[0] as String,
            row[1] as String,
          ),
      ];
    }
    return HanjaCatalog(bySyllable);
  }

  List<HanjaChoice> choicesFor(String syllable) =>
      bySyllable[syllable] ?? const [];
}

bool isHangulSyllable(int rune) => rune >= 0xAC00 && rune <= 0xD7A3;

List<String> hangulSyllables(String name) {
  return [
    for (final rune in name.runes)
      if (isHangulSyllable(rune)) String.fromCharCode(rune),
  ];
}

/// 같은 자리의 한글이 그대로면 고른 한자를 유지한다.
List<String> realignHanjaPicks(
  List<String> previousSyllables,
  List<String> previousPicks,
  List<String> nextSyllables,
) {
  final next = List<String>.filled(nextSyllables.length, '');
  final limit = previousSyllables.length < nextSyllables.length
      ? previousSyllables.length
      : nextSyllables.length;
  for (var i = 0; i < limit; i++) {
    if (previousSyllables[i] == nextSyllables[i] && i < previousPicks.length) {
      next[i] = previousPicks[i];
    }
  }
  return next;
}

List<String> picksFromSavedHanja(List<String> syllables, String hanja) {
  final chars = hanja.runes.map(String.fromCharCode).toList();
  if (chars.length == syllables.length) return chars;
  return List<String>.filled(syllables.length, '');
}
