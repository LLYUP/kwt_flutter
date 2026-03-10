import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/presentation/course_selection/providers/course_selection_provider.dart';

class CourseSelectionPage extends ConsumerStatefulWidget {
  const CourseSelectionPage({super.key});

  @override
  ConsumerState<CourseSelectionPage> createState() => _CourseSelectionPageState();
}

class _CourseSelectionPageState extends ConsumerState<CourseSelectionPage> {
  String _selectedTerm = AppConfig.defaultTerm;
  String _selectedType = 'skjg'; // skjg: 选课日志, tkjg: 退课日志

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    ref.read(courseSelectionProvider.notifier).fetchResults(
      _selectedTerm,
      cxsj: _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseSelectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('选课结果查询'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: state.isLoading ? null : _fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部控制选项卡
          _buildControlPanel(context),
          // 数据列表展示
          const Divider(height: 1),
          Expanded(
            child: _buildBody(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '学期',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: _selectedTerm,
              // 这里简化处理，直接使用当前学期及前后几个学期作为选项，后续可以接入通用的学期拉取Provider
              items: _generateTermOptions().map((term) {
                return DropdownMenuItem(
                  value: term,
                  child: Text(term),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null && val != _selectedTerm) {
                  setState(() => _selectedTerm = val);
                  _fetchData();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '查询类型',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'skjg', child: Text('选课日志')),
                DropdownMenuItem(value: 'tkjg', child: Text('退课日志')),
              ],
              onChanged: (val) {
                if (val != null && val != _selectedType) {
                  setState(() => _selectedType = val);
                  _fetchData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generateTermOptions() {
    final now = DateTime.now();
    int year = now.year;
    return [
      '${year}-${year + 1}-2',
      '${year}-${year + 1}-1',
      '${year - 1}-${year}-2',
      '${year - 1}-${year}-1',
      '${year - 2}-${year - 1}-2',
      '${year - 2}-${year - 1}-1',
      '${year - 3}-${year - 2}-2',
      '${year - 3}-${year - 2}-1',
    ];
  }

  Widget _buildBody(BuildContext context, CourseSelectionState state) {
    if (state.isLoading && (state.results == null || state.results!.isEmpty)) {
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
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.results == null || state.results!.isEmpty) {
      return const Center(child: Text('暂无相关记录'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.results!.length,
      itemBuilder: (context, index) {
        final entry = state.results![index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                entry.index,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(
              entry.courseName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${entry.teacher} | ${entry.credits}学分'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('课程编号', entry.courseCode),
                    const SizedBox(height: 8),
                    _buildDetailRow('上课教师', entry.teacher),
                    const SizedBox(height: 8),
                    _buildDetailRow('总学时', entry.totalHours),
                    const SizedBox(height: 8),
                    _buildDetailRow('学分', entry.credits),
                    const SizedBox(height: 8),
                    _buildDetailRow('课程属性', entry.courseAttr),
                    const SizedBox(height: 8),
                    _buildDetailRow('课程性质', entry.courseNature),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
