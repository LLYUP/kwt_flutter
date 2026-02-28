import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/grades/controllers/grades_controller.dart';
import 'package:kwt_flutter/common/widget/detail_row.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';

class GradesPage extends ConsumerStatefulWidget {
  const GradesPage({super.key});

  @override
  ConsumerState<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends ConsumerState<GradesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradesControllerProvider.notifier).fetchGrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradesControllerProvider);
    final controller = ref.read(gradesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('课程成绩'),
        actions: [
          // 学期选择（对齐 schedule-getx 的 AppBar action 模式）
          if (state.termOptions.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.select_all_rounded, color: Theme.of(context).colorScheme.onSurface),
              onSelected: (v) {
                controller.setTerm(v);
                controller.fetchGrades();
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
              ? AppErrorWidget(message: state.error!, onRetry: () => controller.fetchGrades())
              : CustomScrollView(
                  slivers: [
                    // 成绩列表（ScoreCard 风格）
                    _sliverGradesList(state),
                    // 暂无成绩
                    _emptyWidget(state),
                  ],
                ),
    );
  }

  /// 成绩列表（对齐 schedule-getx 的 ScoreCardComponent）
  Widget _sliverGradesList(GradesState state) {
    return SliverList.builder(
      itemCount: state.filteredGrades.length,
      itemBuilder: (context, index) {
        final grade = state.filteredGrades[index];
        return _ScoreCard(
          subjectName: grade.courseName,
          subTitle: 'GPA: ${grade.gpa}  |  学分: ${grade.credit}',
          score: grade.score,
          onTap: () => _showGradeDetail(grade),
        );
      },
    );
  }

  /// 暂无成绩
  Widget _emptyWidget(GradesState state) {
    if (state.filteredGrades.isEmpty && !state.isBusy) {
      return const SliverFillRemaining(
        child: AppEmptyWidget(message: '暂无成绩数据'),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox());
  }

  void _showGradeDetail(GradeEntry grade) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(grade.courseName, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailRow(label: '课程代码', value: grade.courseCode, icon: Icons.code),
            DetailRow(label: '成绩', value: grade.score, icon: Icons.score),
            DetailRow(label: '学分', value: grade.credit, icon: Icons.star),
            DetailRow(label: 'GPA', value: grade.gpa, icon: Icons.trending_up),
            DetailRow(label: '学时', value: grade.totalHours, icon: Icons.access_time),
            DetailRow(label: '课程属性', value: grade.courseAttr, icon: Icons.category),
            DetailRow(label: '课程性质', value: grade.courseNature, icon: Icons.school),
            DetailRow(label: '考试类型', value: grade.examType, icon: Icons.quiz),
            if (grade.generalType.isNotEmpty)
              DetailRow(label: '通选课类别', value: grade.generalType, icon: Icons.label),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 成绩卡片组件（对齐 schedule-getx 的 ScoreCardComponent）
/// Card + surfaceTintColor, 左侧课程名+副标题, 右侧成绩
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.subjectName,
    this.subTitle,
    this.score,
    this.onTap,
  });
  final String subjectName;
  final String? subTitle;
  final String? score;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      surfaceTintColor: scheme.primary,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左侧：课程名 + 副标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subjectName,
                      style: TextStyle(
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subTitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subTitle!,
                        style: TextStyle(
                          color: scheme.tertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 右侧：成绩
              SizedBox(
                width: 60,
                child: Text(
                  score ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
