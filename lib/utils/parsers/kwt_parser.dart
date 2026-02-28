import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:kwt_flutter/models/models.dart';

/// 科文通 HTML 解析器：负责将所有后端返回的 HTML 解析为结构化模型
class KwtParser {
  /// 单例防止实例化
  KwtParser._();

  /// 解析学期选项
  static List<String> parseTermOptions(String html) {
    final document = html_parser.parse(html);
    final Set<String> termSet = {};
    for (final sel in document.querySelectorAll('select')) {
      final id = sel.id.toLowerCase();
      final name = (sel.attributes['name'] ?? '').toLowerCase();
      if (id.contains('kksj') || name.contains('kksj') || id.contains('xnxq') || name.contains('xnxq')) {
        for (final opt in sel.querySelectorAll('option')) {
          String v = (opt.attributes['value'] ?? '').trim();
          final t = opt.text.trim();
          if (v.isEmpty && t.isNotEmpty) v = t;
          final m = RegExp(r'(\d{4})-(\d{4})-(\d)').firstMatch(v) ?? 
                    RegExp(r'(\d{4})[^\d]+(\d{4})[^\d]+(\d)').firstMatch(v) ?? 
                    RegExp(r'(\d{4})-(\d)').firstMatch(v);
          if (m != null) {
            if (m.groupCount == 3) {
              termSet.add('${m.group(1)}-${m.group(2)}-${m.group(3)}');
            } else if (m.groupCount == 2) {
              final y1 = int.tryParse(m.group(1) ?? '0') ?? 0;
              final y2 = (y1 + 1).toString().padLeft(4, '0');
              termSet.add('${m.group(1)}-$y2-${m.group(2)}');
            }
          }
        }
      }
    }
    final allText = document.documentElement?.text ?? '';
    for (final m in RegExp(r'(\d{4})-(\d{4})-(\d)').allMatches(allText)) {
      termSet.add('${m.group(1)}-${m.group(2)}-${m.group(3)}');
    }
    return termSet.toList();
  }

  /// 解析个人信息
  static Map<String, String> parseProfileInfo(String html) {
    final doc = html_parser.parse(html);
    String name = '';
    final userLi = doc.querySelector('li.user');
    if (userLi != null) {
      final next = userLi.nextElementSibling;
      if (next != null) {
        name = next.querySelector('span')?.text.trim() ?? '';
      }
    }
    if (name.isEmpty) {
      final candidates = doc.querySelectorAll('span');
      for (final s in candidates) {
        final t = s.text.trim();
        if (RegExp(r'^[\u4e00-\u9fa5]{2,6}$').hasMatch(t)) {
          name = t;
          break;
        }
      }
    }
    return {'name': name};
  }

  /// 提取通用表格行数据
  static List<List<String>> extractTableRows(String html) {
    final document = html_parser.parse(html);
    final rows = <List<String>>[];
    final tables = document.querySelectorAll('table');
    if (tables.isEmpty) return rows;
    final table = tables.first;
    for (final tr in table.querySelectorAll('tr')) {
      final cells = tr.querySelectorAll('th,td').map((e) => e.text.trim()).where((t) => t.isNotEmpty).toList();
      if (cells.isNotEmpty) rows.add(cells);
    }
    return rows;
  }

  /// 解析成绩页面
  static List<GradeEntry> parseGrades(String html) {
    final document = html_parser.parse(html);
    final table = document.querySelector('#dataList') ?? document.querySelector('table');
    if (table == null) return [];
    final rows = table.querySelectorAll('tr');
    final entries = <GradeEntry>[];
    
    final headerCells = rows.isNotEmpty ? rows.first.querySelectorAll('th,td') : <dom.Element>[];
    final headers = headerCells.map((e) => e.text.trim()).toList();
    
    int idx(String name, List<String> alt) {
      final all = [name, ...alt];
      for (final n in all) {
        final j = headers.indexWhere((h) => h.contains(n));
        if (j >= 0) return j;
      }
      return -1;
    }
    
    final iTerm = idx('学期', ['开课学期', '开课时间']);
    final iCode = idx('课程编号', ['课程代码', '课程代号']);
    final iName = idx('课程名称', ['课程名']);
    final iScore = idx('成绩', ['总评']);
    final iCredit = idx('学分', []);
    final iHours = idx('总学时', ['学时']);
    final iGpa = idx('绩点', []);
    final iExamType = idx('考试性质', ['考试类型']);
    final iCourseAttr = idx('课程属性', ['属性']);
    final iCourseNature = idx('课程性质', ['性质']);

    for (int r = 1; r < rows.length; r++) {
      final cells = rows[r].querySelectorAll('th,td');
      if (cells.length < 3) continue;
      String at(int i) => i >= 0 && i < cells.length ? cells[i].text.trim() : '';
      entries.add(GradeEntry(
        term: at(iTerm),
        courseCode: at(iCode),
        courseName: at(iName),
        score: at(iScore),
        scoreFlag: '',
        credit: at(iCredit),
        totalHours: at(iHours),
        gpa: at(iGpa),
        examType: at(iExamType),
        examNature: '',
        courseAttr: at(iCourseAttr),
        courseNature: at(iCourseNature),
        generalType: '',
      ));
    }
    return entries;
  }

  /// 解析个人课表
  static List<TimetableEntry> parsePersonalTimetableStructured(String html) {
    final document = html_parser.parse(html);
    final tbody = document.querySelector('table tbody');
    if (tbody == null) return [];
    final result = <TimetableEntry>[];
    final rows = tbody.querySelectorAll('tr');
    
    for (final row in rows) {
      final tds = row.querySelectorAll('td');
      if (tds.isEmpty) continue;
      final firstText = tds.first.text.trim();
      int sectionIndex = 0;
      if (firstText.contains('大节')) {
        if (firstText.contains('第一')) sectionIndex = 1;
        if (firstText.contains('第二')) sectionIndex = 2;
        if (firstText.contains('第三')) sectionIndex = 3;
        if (firstText.contains('第四')) sectionIndex = 4;
        if (firstText.contains('第五')) sectionIndex = 5;
      } else {
        continue;
      }
      
      for (int i = 1; i < tds.length && i <= 7; i++) {
        final td = tds[i];
        final boxes = td.querySelectorAll('span.box');
        for (final box in boxes) {
          final detail = box.nextElementSibling;
          String courseName = '';
          String teacher = '';
          String credits = '';
          String location = '';
          String sectionText = '';
          String weekText = '';
          final ps = box.querySelectorAll('p');
          if (ps.isNotEmpty) courseName = ps.first.text.trim();
          if (ps.length > 1) teacher = ps[1].text.replaceAll('教师：', '').trim();
          final hint = box.querySelector('span.text')?.text.trim() ?? '';
          if (hint.contains('小节')) {
            final parts = hint.split(' ');
            if (parts.isNotEmpty) sectionText = parts[0];
            if (parts.length > 1) weekText = parts[1];
          }
          if (detail != null) {
            final pTitle = detail.querySelector('p');
            if (pTitle != null && pTitle.text.trim().isNotEmpty) {
              courseName = pTitle.text.trim();
            }
            final spans = detail.querySelectorAll('div.tch-name span');
            if (spans.isNotEmpty) {
              credits = spans.first.text.replaceAll('学分：', '').trim();
            }
            final infoSpans = detail.querySelectorAll('div span');
            for (final s in infoSpans) {
              final t = s.text.trim();
              if (t.contains('潘安湖') || t.contains('楼')) {
                location = t;
              }
              if (t.contains('星期')) {
                weekText = t;
              }
            }
          }
          result.add(TimetableEntry(
            courseName: courseName,
            teacher: teacher,
            credits: credits,
            location: location,
            sectionText: sectionText,
            weekText: weekText,
            dayOfWeek: i,
            sectionIndex: sectionIndex,
          ));
        }
      }
    }
    return result;
  }

  /// 解析等级考试
  static List<ExamLevelEntry> parseExamLevel(String html) {
    final document = html_parser.parse(html);
    final table = document.querySelector('#dataList');
    if (table == null) return [];
    final rows = table.querySelectorAll('tr');
    final result = <ExamLevelEntry>[];
    for (int i = 2; i < rows.length; i++) {
      final cells = rows[i].querySelectorAll('td');
      if (cells.length < 11) continue;
      String txt(dom.Element e) => e.text.trim();
      result.add(ExamLevelEntry(
        course: txt(cells[1]),
        writtenScore: txt(cells[2]),
        labScore: txt(cells[3]),
        totalScore: txt(cells[4]),
        writtenLevel: txt(cells[6]),
        labLevel: txt(cells[7]),
        totalLevel: txt(cells[8]),
        startDate: txt(cells[9]),
        endDate: txt(cells[10]),
      ));
    }
    return result;
  }

  /// 解析班级课表
  static List<TimetableEntry> parseClassTimetableStructured(String html) {
    final document = html_parser.parse(html);
    final table = document.querySelector('#timetable');
    if (table == null) return [];

    final List<String> slotLabels = [];
    try {
      final thead = table.querySelector('thead');
      final headerRows = thead?.querySelectorAll('tr') ?? const [];
      if (headerRows.length >= 2) {
        final tdCells = headerRows[1].querySelectorAll('td');
        if (tdCells.length >= 8) {
          for (int k = 1; k <= 7 && k < tdCells.length; k++) {
            slotLabels.add(tdCells[k].text.trim());
          }
        }
      }
    } catch (_) {}

    String sectionTextFromLabel(String raw) {
      final s = raw.replaceAll(RegExp(r"\s+"), '');
      if (s.isEmpty) return '';
      if (RegExp(r'^\d{4}$').hasMatch(s)) {
        final a = s.substring(0, 2);
        final b = s.substring(2, 4);
        return '第$a-$b节';
      }
      if (RegExp(r'^\d{6}$').hasMatch(s)) {
        final a = s.substring(0, 2);
        final b = s.substring(4, 6);
        return '第$a-$b节';
      }
      if (RegExp(r'^\d{1,2}$').hasMatch(s)) {
        return '第${s.padLeft(2, '0')}节';
      }
      return s;
    }

    final result = <TimetableEntry>[];
    final allRows = table.querySelectorAll('tr');
    for (int r = 2; r < allRows.length; r++) {
      final tds = allRows[r].querySelectorAll('td');
      if (tds.isEmpty) continue;
      for (int i = 1; i < tds.length; i++) {
        final td = tds[i];
        final blocks = td.querySelectorAll('div.kbcontent1');
        if (blocks.isEmpty) continue;
        
        final int dayOfWeek = ((i - 1) ~/ 7) + 1;
        final int slotIndex = ((i - 1) % 7) + 1;
        final int sectionIndex = slotIndex <= 5 ? slotIndex : 5;
        final String slotLabel = (slotLabels.length == 7) ? slotLabels[slotIndex - 1] : '';

        for (final div in blocks) {
          final lines = <String>[];
          final sb = StringBuffer();
          for (final node in div.nodes) {
            if (node.nodeType == dom.Node.TEXT_NODE) {
              sb.write(node.text);
            } else if (node is dom.Element && node.localName == 'br') {
              final txt = sb.toString().trim();
              if (txt.isNotEmpty) lines.add(txt);
              sb.clear();
            }
          }
          final tail = sb.toString().trim();
          if (tail.isNotEmpty) lines.add(tail);
          
          String courseName = '';
          String teacher = '';
          String credits = '';
          String location = '';
          String sectionText = '';
          String weekText = '';
          
          if (lines.isNotEmpty) courseName = lines[0];
          for (final line in lines) {
            if (line.contains('周')) {
              weekText = line;
              break;
            }
          }
          if (lines.length >= 4 && (lines[1].startsWith('(') || lines[1].startsWith('（'))) {
            teacher = lines[3].replaceAll(RegExp(r'^教师[:：]?'), '').trim();
          } else if (lines.length >= 3) {
            teacher = lines[2].replaceAll(RegExp(r'^教师[:：]?'), '').trim();
          }
          if (lines.isNotEmpty) {
            location = lines.last;
          }
          for (final line in lines) {
            final m = RegExp(r'(\d{1,2})\s*[-~至]\s*(\d{1,2})\s*节').firstMatch(line);
            if (m != null) {
              sectionText = '${m.group(1)!.padLeft(2, '0')}~${m.group(2)!.padLeft(2, '0')}节';
              break;
            }
          }
          if (sectionText.isEmpty) {
            sectionText = sectionTextFromLabel(slotLabel);
          }
          
          result.add(TimetableEntry(
            courseName: courseName,
            teacher: teacher,
            credits: credits,
            location: location,
            sectionText: sectionText,
            weekText: weekText,
            dayOfWeek: dayOfWeek,
            sectionIndex: sectionIndex,
          ));
        }
      }
    }
    return result;
  }
}
