import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/timetable/controllers/classroom_timetable_controller.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';
import 'package:kwt_flutter/utils/timetable_utils.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';

class ClassroomTimetablePage extends ConsumerStatefulWidget {
  const ClassroomTimetablePage({super.key});

  @override
  ConsumerState<ClassroomTimetablePage> createState() => _ClassroomTimetablePageState();
}

class _ClassroomTimetablePageState extends ConsumerState<ClassroomTimetablePage> {
  final _classCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _classCtrl.addListener(() {
      ref.read(classroomTimetableControllerProvider.notifier).setClassroomQuery(_classCtrl.text);
    });
  }

  @override
  void dispose() {
    _classCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classroomTimetableControllerProvider);
    final controller = ref.read(classroomTimetableControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    if (_classCtrl.text != state.classroomQuery) {
      _classCtrl.value = _classCtrl.value.copyWith(
        text: state.classroomQuery,
        selection: TextSelection.collapsed(offset: state.classroomQuery.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('教室课表'),
        actions: [
          if (state.termOptions.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.select_all_rounded, color: scheme.onSurface),
              onSelected: (v) {
                controller.setTerm(v);
                if (state.classroomQuery.trim().isNotEmpty) controller.fetchTimetable();
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

  Widget _classInputWidget(ClassroomTimetableState state, ClassroomTimetableController controller, ColorScheme scheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Autocomplete<Map<String, String>>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  final keyword = textEditingValue.text.trim();
                  if (keyword.isEmpty) {
                    return const Iterable<Map<String, String>>.empty();
                  }

                  // 简单的防抖处理
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (_classCtrl.text.trim() != keyword) {
                    return const Iterable<Map<String, String>>.empty();
                  }

                  final client = ref.read(kwtClientProvider);
                  if (client == null) return const Iterable<Map<String, String>>.empty();

                  try {
                    return await client.searchClassrooms(keyword: keyword);
                  } catch (_) {
                    return const Iterable<Map<String, String>>.empty();
                  }
                },
                displayStringForOption: (option) => option['name'] ?? '',
                onSelected: (option) {
                  _classCtrl.text = option['name'] ?? '';
                  controller.setClassroom(option['name'] ?? '', option['id'] ?? '');
                  FocusScope.of(context).unfocus();
                  controller.fetchTimetable();
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  if (textEditingController.text != _classCtrl.text && _classCtrl.text.isNotEmpty) {
                    textEditingController.text = _classCtrl.text;
                  }
                  
                  textEditingController.addListener(() {
                    if (_classCtrl.text != textEditingController.text) {
                      _classCtrl.text = textEditingController.text;
                    }
                  });

                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onSubmitted: (v) {
                      onFieldSubmitted();
                      controller.fetchTimetable();
                    },
                    decoration: const InputDecoration(
                      labelText: '教室名称 (如: 潘安湖教3楼-228)',
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 100,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option['name'] ?? ''),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
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

  Widget _gridWidget(ClassroomTimetableState state) {
    final grid = _buildGrid(state.timetable);
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Column(
        children: [
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
                    if (entries[i].teacher.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entries[i].teacher,
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
      child: AppEmptyWidget(message: '请输入教室名称并查询'),
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
            if (entry.credits.isNotEmpty) _detailLine('班级/信息', entry.credits),
            _detailLine('周数', entry.weekText),
            _detailLine('教室', entry.location),
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
