import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/course_selection_center/providers/course_selection_center_provider.dart';

const _weekdayOptions = <MapEntry<String, String>>[
  MapEntry('', '不限'),
  MapEntry('1', '星期一'),
  MapEntry('2', '星期二'),
  MapEntry('3', '星期三'),
  MapEntry('4', '星期四'),
  MapEntry('5', '星期五'),
  MapEntry('6', '星期六'),
  MapEntry('7', '星期日'),
];

class CourseSelectionDetailPage extends ConsumerStatefulWidget {
  final String roundId;
  final String roundName;

  const CourseSelectionDetailPage({
    super.key,
    required this.roundId,
    required this.roundName,
  });

  @override
  ConsumerState<CourseSelectionDetailPage> createState() => _CourseSelectionDetailPageState();
}

class _CourseSelectionDetailPageState extends ConsumerState<CourseSelectionDetailPage> {
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  String _categoryId = '';
  String _weekday = '';
  String _startPeriod = '';
  String _endPeriod = '';
  bool _filterFull = false;
  bool _filterConflict = true;
  bool _filterRestricted = true;
  bool _isExiting = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 并行加载类别和课程列表
      ref.read(electiveCourseListProvider(widget.roundId).notifier).loadCategories();
      _fetchCourses();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  CourseFilterParams _buildFilter() {
    return CourseFilterParams(
      categoryId: _categoryId,
      courseName: _nameController.text.trim(),
      teacher: _teacherController.text.trim(),
      weekday: _weekday,
      startPeriod: _startPeriod,
      endPeriod: _endPeriod,
      filterFull: _filterFull,
      filterConflict: _filterConflict,
      filterRestricted: _filterRestricted,
    );
  }

  void _fetchCourses() {
    ref.read(electiveCourseListProvider(widget.roundId).notifier).fetchCourses(_buildFilter());
  }

  Future<void> _exitSelection() async {
    setState(() => _isExiting = true);
    try {
      await ref.read(electiveCourseListProvider(widget.roundId).notifier).exitSelection();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('退出失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExiting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(electiveCourseListProvider(widget.roundId));
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _exitSelection();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.roundName, style: const TextStyle(fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isExiting ? null : _exitSelection,
          ),
          actions: [
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
              tooltip: _showFilters ? '收起筛选' : '展开筛选',
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_showFilters) _buildFilterPanel(context, scheme, state),
            if (_showFilters) const Divider(height: 1),
            Expanded(child: _buildBody(context, state, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, ColorScheme scheme, ElectiveCourseListState state) {
    // 使用动态加载的类别，如果尚未加载则显示默认
    final categoryItems = state.categories.isNotEmpty
        ? state.categories
        : const [MapEntry('', '全部类别')];

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 通选课类别
          _buildDropdown(
            label: '通选课类别',
            value: _categoryId,
            items: categoryItems,
            onChanged: (v) => setState(() => _categoryId = v ?? ''),
          ),
          const SizedBox(height: 8),
          // 课程(编号/名称) + 上课教师
          Row(
            children: [
              Expanded(child: _buildTextField(_nameController, '课程(编号/名称)')),
              const SizedBox(width: 8),
              Expanded(child: _buildTextField(_teacherController, '上课教师')),
            ],
          ),
          const SizedBox(height: 8),
          // 星期 + 节次范围
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: '星期',
                  value: _weekday,
                  items: _weekdayOptions,
                  onChanged: (v) => setState(() => _weekday = v ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: '节次',
                        value: _startPeriod,
                        items: _periodOptions(),
                        onChanged: (v) => setState(() => _startPeriod = v ?? ''),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('~'),
                    ),
                    Expanded(
                      child: _buildDropdown(
                        label: '',
                        value: _endPeriod,
                        items: _periodOptions(),
                        onChanged: (v) => setState(() => _endPeriod = v ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 复选框行
          Wrap(
            spacing: 12,
            children: [
              _buildCheckbox('过滤已满', _filterFull, (v) => setState(() => _filterFull = v ?? false)),
              _buildCheckbox('过滤冲突', _filterConflict, (v) => setState(() => _filterConflict = v ?? true)),
              _buildCheckbox('过滤限选', _filterRestricted, (v) => setState(() => _filterRestricted = v ?? true)),
            ],
          ),
          const SizedBox(height: 8),
          // 查询按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isLoading ? null : _fetchCourses,
              icon: state.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search, size: 18),
              label: Text(state.isLoading ? '查询中...' : '查询'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<MapEntry<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      value: value,
      isExpanded: true,
      items: items.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      style: const TextStyle(fontSize: 13),
      onSubmitted: (_) => _fetchCourses(),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24, height: 24,
          child: Checkbox(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  List<MapEntry<String, String>> _periodOptions() {
    return [
      const MapEntry('', '不限'),
      ...List.generate(14, (i) => MapEntry('${i + 1}', '第${i + 1}节')),
    ];
  }

  Widget _buildBody(BuildContext context, ElectiveCourseListState state, ColorScheme scheme) {
    if (state.isLoading && state.courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败\n${state.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchCourses, child: const Text('重试')),
          ],
        ),
      );
    }

    if (state.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text('暂无可选课程', style: TextStyle(color: scheme.outline, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchCourses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: state.courses.length,
        itemBuilder: (context, index) {
          final course = state.courses[index];
          return _buildCourseCard(context, course, scheme);
        },
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, ElectiveCourseEntry course, ColorScheme scheme) {
    final isFull = course.remainingCount <= 0 && course.maxCapacity > 0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        key: PageStorageKey('course_${course.jx02id}_${course.jx0404id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isFull ? Colors.red.shade100 : scheme.primaryContainer,
          child: Icon(
            course.isNetworkCourse ? Icons.language : Icons.school,
            size: 18,
            color: isFull ? Colors.red.shade700 : scheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          course.courseName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text('${course.credits}学分', style: TextStyle(fontSize: 12, color: scheme.primary)),
            const SizedBox(width: 8),
            Text(course.teacher.isEmpty ? '网络课' : course.teacher, style: const TextStyle(fontSize: 12)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isFull ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isFull ? '已满' : '${course.enrolledCount}/${course.maxCapacity}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isFull ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        children: [
          _detailRow('课程编号', course.courseCode),
          _detailRow('课程分类', course.category),
          _detailRow('课程性质', course.courseType),
          _detailRow('总学时', '${course.totalHours}'),
          _detailRow('校区', course.campus),
          if (course.classTime.isNotEmpty) _detailRow('上课时间', course.classTime),
          if (course.classLocation.isNotEmpty) _detailRow('上课地点', course.classLocation),
          _detailRow('是否网络课', course.isNetworkCourse ? '是' : '否'),
          _detailRow('已选/容量', '${course.enrolledCount} / ${course.maxCapacity}'),
          if (course.remainingCount > 0) _detailRow('剩余名额', '${course.remainingCount}'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: course.isSelected
                ? OutlinedButton.icon(
                    onPressed: () => _onDeselectCourse(course),
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('退课'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _onSelectCourse(course),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('选课'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelectCourse(ElectiveCourseEntry course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认选课'),
        content: Text('确定选择「${course.courseName}」？\n学分: ${course.credits}  教师: ${course.teacher.isEmpty ? "网络课" : course.teacher}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认选课')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final result = await ref.read(electiveCourseListProvider(widget.roundId).notifier).selectCourse(
        jx0404id: course.jx0404id,
        kcid: course.jx02id,
      );

      if (mounted) {
        final success = result['success'] == true;
        final message = result['message']?.toString() ?? (success ? '选课成功' : '选课失败');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选课失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onDeselectCourse(ElectiveCourseEntry course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退课'),
        content: Text('确定退选「${course.courseName}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('确认退课'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final result = await ref.read(electiveCourseListProvider(widget.roundId).notifier).deselectCourse(
        jx0404id: course.jx0404id,
      );

      if (mounted) {
        final success = result['success'] == true;
        final message = result['message']?.toString() ?? (success ? '退课成功' : '退课失败');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('退课失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
