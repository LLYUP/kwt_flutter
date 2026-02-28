// 个人课表页面：按周展示个人课表，支持自动推算周次、选择周次与刷新
// 对齐 schedule-getx 的 CurriculumComponent 风格
import 'package:flutter/material.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/services/session_service.dart';
import 'package:kwt_flutter/services/settings.dart';
import 'package:kwt_flutter/utils/timetable_utils.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';
import 'package:kwt_flutter/config/app_config.dart';

/// 个人课表页
class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage> {
  final _settings = SettingsService();
  final _termCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeModeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  List<MergedTimetableEntry> _mergedTimetable = const [];
  int _weekNo = 1;

  @override
  void initState() {
    super.initState();
    _initFromSettings();
  }

  Future<void> _initFromSettings() async {
    _termCtrl.text = await _settings.getTerm() ?? AppConfig.defaultTerm;
    final savedStart = await _settings.getStartDate() ?? '';
    _timeModeCtrl.text = AppConfig.defaultTimeMode;

    if (savedStart.isNotEmpty) {
      final autoWeek = _computeWeekFromStart(savedStart);
      _weekNo = autoWeek;
      final start = DateTime.tryParse(savedStart);
      if (start != null) {
        final rq = start.add(Duration(days: (autoWeek - 1) * 7));
        _dateCtrl.text = rq.toIso8601String().substring(0, 10);
      }
    } else {
      _dateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
      _weekNo = 1;
    }

    await _load();
  }

  @override
  void dispose() {
    _termCtrl.dispose();
    _dateCtrl.dispose();
    _timeModeCtrl.dispose();
    super.dispose();
  }

  int _computeWeekFromStart(String startDate) {
    final start = DateTime.tryParse(startDate);
    if (start == null) return 1;
    final now = DateTime.now();
    final diff = now.difference(DateTime(start.year, start.month, start.day)).inDays;
    if (diff < 0) return 1;
    final week = (diff ~/ 7) + 1;
    return week < 1 ? 1 : week;
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = ref.read(sessionServiceProvider);
      final data = await session.safeCall(context, () =>
        session.client.fetchPersonalTimetableStructured(
          date: _dateCtrl.text.trim(),
          timeMode: _timeModeCtrl.text.trim(),
          termId: _termCtrl.text.trim(),
        ),
      );
      if (data != null) {
        setState(() {
          _mergedTimetable = mergeContinuousCourses(data);
        });
      }
    } catch (e) {
      setState(() => _error = '加载失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monday = _calcMonday();
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: _error != null
            ? AppErrorWidget(message: _error!, onRetry: _load)
            : _busy
                ? const AppLoadingWidget()
                : CustomScrollView(
                    slivers: [
                      // 周次大标题（对齐 schedule-getx）
                      _weekTitleSliver(days, scheme),
                      // 星期日期行
                      _weekdayHeaderSliver(days, scheme),
                      // 课表网格
                      _timetableGridSliver(days, scheme),
                      // 底部间距
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
      ),
    );
  }

  /// 周次标题 sliver
  Widget _weekTitleSliver(List<DateTime> days, ColorScheme scheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _busy ? null : _pickWeek,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '第$_weekNo周',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Text(
                '${days.first.year}年${days.first.month}月',
                style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filledTonal(
                onPressed: _busy ? null : _load,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 星期日期表头 sliver（对齐 schedule-getx 的 _getDateWeek）
  Widget _weekdayHeaderSliver(List<DateTime> days, ColorScheme scheme) {
    final today = DateTime.now();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // 空占位（与节次列对齐）
            const SizedBox(width: 36),
            const SizedBox(width: 6),
            for (int i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: (days[i].year == today.year &&
                            days[i].month == today.month &&
                            days[i].day == today.day)
                        ? scheme.primary.withValues(alpha: 0.15)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _weekdayName(i + 1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${days[i].month}.${days[i].day}',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 课表网格（5个节次段，每段高度自适应, 对齐 schedule-getx 的 _getTimeAndCourseList）
  Widget _timetableGridSliver(List<DateTime> days, ColorScheme scheme) {
    // 构建按节次段+星期的课程映射
    final grid = _buildSectionDayGrid();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            for (int section = 0; section < 5; section++) ...[
              if (section == 2) _breakLabel('午休', scheme),
              if (section == 4) _breakLabel('晚休', scheme),
              _sectionRow(section, grid, scheme),
            ],
          ],
        ),
      ),
    );
  }

  /// 一个节次段（对齐 schedule-getx 的一行 8 个格子：节次 + 7天）
  Widget _sectionRow(int sectionIdx, List<List<List<MergedTimetableEntry>>> grid, ColorScheme scheme) {
    const sectionLabels = ['一', '二', '三', '四', '五'];
    const sectionTimes = [
      '08:15\n08:55',
      '09:00\n09:40',
      '09:55\n10:35\n10:40\n11:20\n11:25\n12:05',
      '13:50\n14:30\n14:35\n15:15\n15:30\n16:10\n16:15\n16:55',
      '18:30\n19:10\n19:15\n19:55\n20:00\n20:40',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 节次列
            SizedBox(
              width: 36,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  sectionLabels[sectionIdx],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 7 天的课程格子
            for (int day = 0; day < 7; day++) ...[
              if (day > 0) const SizedBox(width: 6),
              Expanded(
                child: _courseCell(grid[sectionIdx][day], scheme),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 课程格子（对齐 schedule-getx 的 _getCourseList）
  Widget _courseCell(List<MergedTimetableEntry> courses, ColorScheme scheme) {
    if (courses.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 72),
      );
    }
    // 取第一个课程显示
    final course = courses.first;
    final colors = _getCourseColors(course.colorHash, scheme);
    return GestureDetector(
      onTap: () => _showCourseDetail(course),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: colors['background'],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            // 课程名称
            Text(
              course.courseName,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors['text'],
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            // 课程地点
            if (course.location.isNotEmpty)
              Text(
                compactLocation(course.location),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: colors['text']!.withValues(alpha: 0.7),
                  height: 1.2,
                ),
              ),
            // 教师
            if (course.teacher.isNotEmpty)
              Text(
                course.teacher,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: colors['text']!.withValues(alpha: 0.6),
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 午休/晚休标签
  Widget _breakLabel(String label, ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      margin: const EdgeInsets.only(bottom: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建 [节次段][星期] 的课程映射（5段 × 7天）
  List<List<List<MergedTimetableEntry>>> _buildSectionDayGrid() {
    // 5个节次段: 1-2节(一), 3-4节(二), 5节(三), 6-8节(四), 9-12节(五)
    // 简化映射：section 1-2→0, 3-5→1, 6→2(午休后第一段), 6-9→3, 10-12→4
    final grid = List.generate(5, (_) => List.generate(7, (_) => <MergedTimetableEntry>[]));

    for (final course in _mergedTimetable) {
      final dayIdx = course.dayOfWeek - 1;
      if (dayIdx < 0 || dayIdx > 6) continue;
      final sectionIdx = _sectionToIndex(course.startSection);
      if (sectionIdx >= 0 && sectionIdx < 5) {
        grid[sectionIdx][dayIdx].add(course);
      }
    }
    return grid;
  }

  /// 将节次号映射到5段索引
  int _sectionToIndex(int section) {
    if (section >= 1 && section <= 2) return 0;
    if (section >= 3 && section <= 5) return 1;
    if (section >= 6 && section <= 7) return 2;
    if (section >= 8 && section <= 9) return 3;
    if (section >= 10 && section <= 12) return 4;
    return -1;
  }

  /// 获取课程颜色（使用 colorScheme 容器色）
  Map<String, Color> _getCourseColors(int hash, ColorScheme scheme) {
    final colors = [
      {'background': scheme.tertiaryContainer.withValues(alpha: 0.8), 'text': scheme.onTertiaryContainer},
      {'background': scheme.primaryContainer.withValues(alpha: 0.8), 'text': scheme.onPrimaryContainer},
      {'background': scheme.secondaryContainer.withValues(alpha: 0.8), 'text': scheme.onSecondaryContainer},
      {'background': scheme.errorContainer.withValues(alpha: 0.6), 'text': scheme.onErrorContainer},
      {'background': scheme.primary.withValues(alpha: 0.15), 'text': scheme.primary},
      {'background': scheme.tertiary.withValues(alpha: 0.15), 'text': scheme.tertiary},
    ];
    return colors[hash.abs() % colors.length];
  }

  /// 课程详情弹窗
  void _showCourseDetail(MergedTimetableEntry course) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('课程详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('课程名称', course.courseName),
            _detailLine('教师', course.teacher),
            _detailLine('时间', '第${course.startSection}-${course.endSection}节'),
            _detailLine('教室', course.location),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text('$label：$value'),
    );
  }

  /// 选择周次
  Future<void> _pickWeek() async {
    final no = await showDialog<int>(
      context: context,
      builder: (_) => _WeekPickerDialog(initial: _weekNo),
    );
    if (no != null) {
      setState(() => _weekNo = no);
      final start = DateTime.tryParse(await _settings.getStartDate() ?? _dateCtrl.text.trim());
      if (start != null) {
        final rq = start.add(Duration(days: (no - 1) * 7));
        _dateCtrl.text = rq.toIso8601String().substring(0, 10);
        _load();
      }
    }
  }

  DateTime _calcMonday() {
    final start = DateTime.tryParse(_dateCtrl.text.trim()) ?? DateTime.now();
    final weekday = start.weekday;
    return start.subtract(Duration(days: weekday - 1));
  }

  String _weekdayName(int i) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[i - 1];
  }
}


class _WeekPickerDialog extends StatefulWidget {
  const _WeekPickerDialog({required this.initial});
  final int initial;
  @override
  State<_WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<_WeekPickerDialog> {
  late int _value;
  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择周次'),
      content: SizedBox(
        width: 260,
        child: DropdownButton<int>(
          isExpanded: true,
          value: _value,
          items: List.generate(25, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text('第$e周'))).toList(),
          onChanged: (v) => setState(() => _value = v ?? _value),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(context, _value), child: const Text('确定')),
      ],
    );
  }
}
