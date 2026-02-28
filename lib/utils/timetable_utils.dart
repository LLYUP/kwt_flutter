

// 统一的地点压缩：去空白、规范破折号、去冗余"潘安湖"，保留后两段
String compactLocation(String raw) {
  var s = raw.replaceAll(RegExp(r"\s+"), "");
  s = s.replaceAll('－', '-').replaceAll('—', '-').replaceAll('–', '-');
  s = s.replaceAll('潘安湖', '');
  final parts = s.split('-').where((e) => e.isNotEmpty).toList();
  if (parts.length >= 2) {
    return parts.sublist(parts.length - 2).join('-');
  }
  return parts.isNotEmpty ? parts.first : s;
}

// 将小节范围推断为第几大节（1..5），失败返回 0
int guessSectionFromText(String sectionText) {
  final m = RegExp(r'(\d{1,2})\s*~\s*(\d{1,2})').firstMatch(sectionText);
  if (m != null) {
    final start = int.tryParse(m.group(1) ?? '0') ?? 0;
    if (start <= 2) return 1;
    if (start <= 4) return 2;
    if (start <= 7) return 3;
    if (start <= 9) return 4;
    return 5;
  }
  return 0;
}
