// 个人课表页面：按周展示个人课表，按教务系统5大节原样展示
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
  List<TimetableEntry> _timetable = const [];
  int _weekNo = 1;

  late final PageController _pageController;
  final int _initialPage = 500;
  late int _currentPageIndex;
  bool _isReverting = false;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = _initialPage;
    _pageController = PageController(initialPage: _initialPage);
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
    _pageController.dispose();
    _termCtrl.dispose();
    _dateCtrl.dispose();
    _timeModeCtrl.dispose();
    super.dispose();
  }

  int _computeWeekFromStart(String startDate) {
    final start = DateTime.tryParse(startDate);
    if (start == null) return 1;
    final now = DateTime.now();
    
    // 找到开学日期的周一 00:00
    final startMonday = DateTime(start.year, start.month, start.day)
        .subtract(Duration(days: start.weekday - 1));
        
    // 找到今天周一 00:00
    final nowMonday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
        
    // 两个周一相差的天数除以7，就是经历的周数
    final diffDays = nowMonday.difference(startMonday).inDays;
    
    if (diffDays < 0) return 1; // 还没开学，显示第一周
    
    return (diffDays ~/ 7) + 1;
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
        setState(() => _timetable = data);
      }
    } catch (e) {
      setState(() => _error = '加载失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            final delta = index - _currentPageIndex;
            _currentPageIndex = index;
            _changeWeek(delta);
          },
          itemBuilder: (context, index) {
            final delta = index - _currentPageIndex;
            final virtualWeekNo = _weekNo + delta;
            
            final currentMonday = _calcMonday();
            final virtualMonday = currentMonday.add(Duration(days: delta * 7));
            final days = List.generate(7, (i) => virtualMonday.add(Duration(days: i)));

            return CustomScrollView(
              slivers: [
                _weekTitleSliver(days, scheme, virtualWeekNo),
                _weekdayHeaderSliver(days, scheme),
                if (index == _currentPageIndex) ...[
                  if (_error != null)
                    SliverFillRemaining(child: AppErrorWidget(message: _error!, onRetry: _load))
                  else if (_busy)
                    SliverFillRemaining(child: const AppLoadingWidget())
                  else
                    _timetableGridSliver(scheme),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ] else ...[
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// 周次标题
  Widget _weekTitleSliver(List<DateTime> days, ColorScheme scheme, int weekNo) {
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
                  '第$weekNo周',
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

  /// 星期日期表头
  Widget _weekdayHeaderSliver(List<DateTime> days, ColorScheme scheme) {
    final today = DateTime.now();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
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

  /// 课表网格：按教务系统原始5个大节展示
  Widget _timetableGridSliver(ColorScheme scheme) {
    // 按大节号(sectionIndex 1-5) + 星期(dayOfWeek 1-7) 组织
    final grid = _buildDajieGrid();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            // 第一大节 (01-02节)
            _sectionRow(0, '一', grid, scheme),
            // 第二大节 (03-05节)
            _sectionRow(1, '二', grid, scheme),
            // 午休
            _breakLabel('午休', scheme),
            // 第三大节 (06-07节)
            _sectionRow(2, '三', grid, scheme),
            // 第四大节 (08-09节)
            _sectionRow(3, '四', grid, scheme),
            // 晚休
            _breakLabel('晚休', scheme),
            // 第五大节 (10-12节)
            _sectionRow(4, '五', grid, scheme),
          ],
        ),
      ),
    );
  }

  /// 一个大节行
  Widget _sectionRow(int idx, String label, List<List<List<TimetableEntry>>> grid, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 大节号
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
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // 7 天
            for (int day = 0; day < 7; day++) ...[
              if (day > 0) const SizedBox(width: 6),
              Expanded(
                child: _courseCell(grid[idx][day], scheme),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 课程格子
  Widget _courseCell(List<TimetableEntry> entries, ColorScheme scheme) {
    if (entries.isEmpty) {
      return Container(constraints: const BoxConstraints(minHeight: 72));
    }
    final entry = entries.first;
    final colorIdx = entry.courseName.hashCode;
    final colors = _getCourseColors(colorIdx, scheme);
    return GestureDetector(
      onTap: () => _showCourseDetail(entry),
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
            Text(
              entry.courseName,
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
            const SizedBox(height: 2),
            if (entry.location.isNotEmpty)
              Text(
                compactLocation(entry.location),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: colors['text']!.withValues(alpha: 0.7),
                  height: 1.2,
                ),
              ),
            if (entry.teacher.isNotEmpty)
              Text(
                entry.teacher,
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

  /// 按大节号(sectionIndex 1-5) + 星期(dayOfWeek 1-7) 构建网格
  /// 直接使用解析器返回的 sectionIndex（对应教务系统的5个大节行）
  List<List<List<TimetableEntry>>> _buildDajieGrid() {
    // 5大节 × 7天
    final grid = List.generate(5, (_) => List.generate(7, (_) => <TimetableEntry>[]));

    for (final entry in _timetable) {
      final dajie = entry.sectionIndex; // 1-5
      final day = entry.dayOfWeek;      // 1-7
      if (dajie >= 1 && dajie <= 5 && day >= 1 && day <= 7) {
        grid[dajie - 1][day - 1].add(entry);
      }
    }
    return grid;
  }

  /// 获取课程颜色
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
  void _showCourseDetail(TimetableEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('课程详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('课程名称', entry.courseName),
            _detailLine('教师', entry.teacher),
            _detailLine('节次', entry.sectionText),
            _detailLine('教室', entry.location),
            if (entry.credits.isNotEmpty) _detailLine('学分', entry.credits),
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

  void _changeWeek(int delta) {
    if (_isReverting) return;
    
    final newWeek = _weekNo + delta;
    if (newWeek < 1 || newWeek > 25) {
      _isReverting = true;
      final previousPage = _currentPageIndex - delta;
      _currentPageIndex = previousPage;
      _pageController.animateToPage(
        previousPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).then((_) => _isReverting = false);
      return;
    }

    final current = DateTime.tryParse(_dateCtrl.text.trim());
    if (current != null) {
      final next = current.add(Duration(days: delta * 7));
      setState(() {
        _weekNo = newWeek;
        _dateCtrl.text = next.toIso8601String().substring(0, 10);
      });
      _load();
    }
  }

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
