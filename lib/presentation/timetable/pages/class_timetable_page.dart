import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/timetable/controllers/class_timetable_controller.dart';
import 'package:kwt_flutter/utils/timetable_utils.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';

class ClassTimetablePage extends ConsumerStatefulWidget {
  const ClassTimetablePage({super.key});

  @override
  ConsumerState<ClassTimetablePage> createState() => _ClassTimetablePageState();
}

class _ClassTimetablePageState extends ConsumerState<ClassTimetablePage> {
  final _classCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _classCtrl.addListener(() {
      ref.read(classTimetableControllerProvider.notifier).setClassQuery(_classCtrl.text);
    });
  }

  @override
  void dispose() {
    _classCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classTimetableControllerProvider);
    final controller = ref.read(classTimetableControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    if (_classCtrl.text != state.classQuery) {
      _classCtrl.value = _classCtrl.value.copyWith(
        text: state.classQuery,
        selection: TextSelection.collapsed(offset: state.classQuery.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('班级课表'),
        actions: [
          if (state.termOptions.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.select_all_rounded, color: scheme.onSurface),
              onSelected: (v) {
                controller.setTerm(v);
                if (state.classQuery.trim().isNotEmpty) controller.fetchTimetable();
              },
              itemBuilder: (_) => state.termOptions
                  .map((e) => PopupMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
        ],
      ),
      body: state.isBusy
          ? const AppLoadingWidget()
          : state.error != null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () {
                    FocusScope.of(context).unfocus();
                    controller.fetchTimetable();
                  },
                )
              : CustomScrollView(
                  slivers: [
                    _classInputWidget(state, controller, scheme),
                    if (state.timetable.isNotEmpty) _gridWidget(state),
                    if (state.timetable.isEmpty && !state.isBusy) _emptyWidget(),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
    );
  }

  Widget _classInputWidget(ClassTimetableState state, ClassTimetableController controller, ColorScheme scheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _classCtrl,
                decoration: const InputDecoration(
                  labelText: '班级名称',
                  prefixIcon: Icon(Icons.class_),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: state.isBusy
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      controller.fetchTimetable();
                    },
              child: const Text('查询'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridWidget(ClassTimetableState state) {
    final grid = _buildGrid(state.timetable);
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // 星期表头
          Container(
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '节次',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                for (int i = 1; i <= 7; i++)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      child: Text(
                        _weekdayName(i),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 课表内容行
          for (int section = 1; section <= 5; section++)
            _gridRow(grid, section, scheme),
        ],
      ),
    );
  }

  Widget _gridRow(Map<int, Map<int, List<TimetableEntry>>> grid, int section, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 节次列
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                border: Border(right: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Center(
                child: Text(
                  ['一', '二', '三', '四', '五'][section - 1],
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // 课程列
            for (int day = 1; day <= 7; day++)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: day == 1 ? BorderSide.none : BorderSide(color: scheme.outlineVariant)),
                  ),
                  child: _cellWidget(grid[section]?[day] ?? const [], scheme),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cellWidget(List<TimetableEntry> entries, ColorScheme scheme) {
    if (entries.isEmpty) {
      return const SizedBox(height: 70);
    }
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minHeight: 70),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(height: 8, color: scheme.outlineVariant),
            GestureDetector(
              onTap: () => _showCourseDetail(entries[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      entries[i].courseName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: scheme.onTertiaryContainer,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entries[i].location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        compactLocation(entries[i].location),
                        style: TextStyle(
                          color: scheme.onTertiaryContainer.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyWidget() {
    return const SliverFillRemaining(
      child: AppEmptyWidget(message: '请输入班级名称并查询'),
    );
  }

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

  String _weekdayName(int i) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[i - 1];
  }

  Map<int, Map<int, List<TimetableEntry>>> _buildGrid(List<TimetableEntry> list) {
    final map = <int, Map<int, List<TimetableEntry>>>{};
    for (final e in list) {
      final section = e.sectionIndex > 0 ? e.sectionIndex : guessSectionFromText(e.sectionText);
      if (section <= 0 || section > 5) continue;
      map.putIfAbsent(section, () => {});
      map[section]!.putIfAbsent(e.dayOfWeek, () => []);
      map[section]![e.dayOfWeek]!.add(e);
    }
    return map;
  }
}
