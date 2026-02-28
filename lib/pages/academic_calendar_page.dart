import 'package:flutter/material.dart';

/// 校历页面：2025-2026 学年第二学期校历
class AcademicCalendar extends StatelessWidget {
  const AcademicCalendar({super.key});

  static const _months = <_MonthSection>[
    _MonthSection('三月', [
      _WeekLine('一', [0, 0, 0, 5, 6, 7, 8]),
      _WeekLine('二', [9, 10, 11, 12, 13, 14, 15]),
      _WeekLine('三', [16, 17, 18, 19, 20, 21, 22]),
      _WeekLine('四', [23, 24, 25, 26, 27, 28, 29]),
      _WeekLine('五', [30, 31, 0, 0, 0, 0, 0]),
    ]),
    _MonthSection('四月', [
      _WeekLine(null, [0, 0, 1, 2, 3, 4, 5]),
      _WeekLine('六', [6, 7, 8, 9, 10, 11, 12]),
      _WeekLine('七', [13, 14, 15, 16, 17, 18, 19]),
      _WeekLine('八', [20, 21, 22, 23, 24, 25, 26]),
      _WeekLine('九', [27, 28, 29, 30, 0, 0, 0]),
    ]),
    _MonthSection('五月', [
      _WeekLine(null, [0, 0, 0, 0, 1, 2, 3]),
      _WeekLine('十', [4, 5, 6, 7, 8, 9, 10]),
      _WeekLine('十一', [11, 12, 13, 14, 15, 16, 17]),
      _WeekLine('十二', [18, 19, 20, 21, 22, 23, 24]),
      _WeekLine('十三', [25, 26, 27, 28, 29, 30, 31]),
    ]),
    _MonthSection('六月', [
      _WeekLine('十四', [1, 2, 3, 4, 5, 6, 7]),
      _WeekLine('十五', [8, 9, 10, 11, 12, 13, 14]),
      _WeekLine('十六', [15, 16, 17, 18, 19, 20, 21]),
      _WeekLine('十七', [22, 23, 24, 25, 26, 27, 28]),
      _WeekLine('十八', [29, 30, 0, 0, 0, 0, 0]),
    ]),
    _MonthSection('七月', [
      _WeekLine(null, [0, 0, 1, 2, 3, 4, 5]),
      _WeekLine('十九', [6, 7, 8, 9, 10, 11, 12]),
      _WeekLine('二十', [13, 0, 0, 0, 0, 0, 0]),
    ]),
  ];

  static const _notes = [
    ('一、', '报到：教职工、学生2026年3月4日'),
    ('二、', '上课：2026年3月5日'),
    ('三、', '节假日：'),
    ('', '国际劳动妇女节，妇女放假半天（不停课）'),
    ('', '清明节，放假1天'),
    ('', '国际劳动节，放假2天'),
    ('', '青年节，青年放假半天（不停课）'),
    ('', '端午节，放假1天'),
    ('', '暑假自2026年7月14日至8月31日'),
    ('', '以上安排如有变动，则另行通知'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '校历',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
        children: [
          // 学期标题
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '2025—2026 学年第二学期校历',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 日历表格
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildHeader(cs),
                for (int i = 0; i < _months.length; i++)
                  _MonthSectionWidget(
                    section: _months[i],
                    isLast: i == _months.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 说明
          _buildNotesCard(cs),
        ],
      ),
    );
  }

  /// 表头行
  Widget _buildHeader(ColorScheme cs) {
    const weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final border = BorderSide(color: cs.outlineVariant, width: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        border: Border(bottom: border),
      ),
      child: Row(
        children: [
          _headerLabel('月份', 50, cs, border),
          _headerLabel('周次', 42, cs, border),
          for (int i = 0; i < 7; i++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: border),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  weekDays[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: i >= 5 ? cs.error : cs.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerLabel(String text, double width, ColorScheme cs, BorderSide border) {
    return Container(
      width: width,
      decoration: BoxDecoration(border: Border(right: border)),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.primary,
        ),
      ),
    );
  }

  Widget _buildNotesCard(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '说明',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final (prefix, text) in _notes)
              Padding(
                padding: EdgeInsets.only(
                  bottom: 5,
                  left: prefix.isEmpty ? 36 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (prefix.isNotEmpty)
                      Text(
                        prefix,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 月份区块组件 —— 月份标签垂直居中跨所有行
class _MonthSectionWidget extends StatelessWidget {
  const _MonthSectionWidget({
    required this.section,
    required this.isLast,
  });

  final _MonthSection section;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = BorderSide(color: cs.outlineVariant, width: 0.5);
    final lines = section.lines;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 月份列：整个月合并为一个格
          Container(
            width: 50,
            decoration: BoxDecoration(
              border: Border(
                right: border,
                bottom: isLast ? BorderSide.none : border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              section.month,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),

          // 周次 + 日期列
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < lines.length; i++)
                  _buildWeekRow(
                    context,
                    lines[i],
                    cs,
                    border,
                    isLastRow: isLast && i == lines.length - 1,
                    // 判断周次是否需要合并到下一行
                    // 如果这是月份最后一行且不是最后一个月，且下一个月第一行 week==null
                    // 则当前行的周次标签需要只显示上半部分
                    mergesDown: !isLast &&
                        i == lines.length - 1 &&
                        lines[i].week != null,
                    // 如果这是月份第一行且 week==null，说明它是上一月最后一周的延续
                    mergesUp: i == 0 && lines[i].week == null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(
    BuildContext context,
    _WeekLine line,
    ColorScheme cs,
    BorderSide border, {
    required bool isLastRow,
    required bool mergesDown,
    required bool mergesUp,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLastRow ? BorderSide.none : border,
        ),
      ),
      child: Row(
        children: [
          // 周次列
          Container(
            width: 42,
            decoration: BoxDecoration(
              border: Border(
                right: border,
                // 如果当前行向下合并，不画底边
                bottom: mergesDown ? BorderSide.none : BorderSide.none,
                // 如果当前行向上合并，不画顶边
                top: mergesUp ? BorderSide.none : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              line.week ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),

          // 7天日期
          for (int d = 0; d < 7; d++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: border),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  line.days[d] == 0 ? '' : line.days[d].toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: d >= 5 ? cs.error : cs.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthSection {
  const _MonthSection(this.month, this.lines);
  final String month;
  final List<_WeekLine> lines;
}

class _WeekLine {
  const _WeekLine(this.week, this.days);
  final String? week; // null = 上月最后一周的延续
  final List<int> days;
}
