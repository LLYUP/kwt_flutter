import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/training_plan/controllers/training_plan_controller.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';

class TrainingPlanPage extends ConsumerWidget {
  const TrainingPlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingPlanControllerProvider);
    final controller = ref.read(trainingPlanControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('培养方案'),
        actions: [
          if (state.termOptions.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list, color: scheme.onSurface),
              initialValue: state.selectedTerm,
              onSelected: (v) => controller.setTerm(v),
              itemBuilder: (_) => state.termOptions
                  .map((e) => PopupMenuItem(
                        value: e,
                        child: Text(e == state.selectedTerm ? '✅ $e' : e),
                      ))
                  .toList(),
            ),
        ],
      ),
      body: _buildBody(context, state, controller, scheme),
    );
  }

  Widget _buildBody(BuildContext context, TrainingPlanState state, TrainingPlanController controller, ColorScheme scheme) {
    if (state.isBusy && state.plans.isEmpty) {
      return const AppLoadingWidget();
    }

    if (state.error != null && state.plans.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => controller.fetchTrainingPlan(),
      );
    }

    if (state.plans.isEmpty) {
      return const AppEmptyWidget(message: '暂无培养方案数据');
    }

    final displayPlans = state.filteredPlans;
    if (displayPlans.isEmpty) {
      return const AppEmptyWidget(message: '该学期暂无培养方案');
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchTrainingPlan(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayPlans.length,
        itemBuilder: (context, index) {
          final plan = displayPlans[index];
          return _PlanCard(plan: plan, scheme: scheme);
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.scheme});

  final TrainingPlanEntry plan;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      plan.courseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(plan.courseAttr, scheme),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.numbers, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    plan.courseCode,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_month, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    plan.term,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star_border, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.credits} 学分',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.totalHours} 学时',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, ColorScheme scheme) {
    Color bgColor = scheme.primaryContainer;
    Color fgColor = scheme.onPrimaryContainer;

    if (text.contains('必修')) {
      bgColor = scheme.errorContainer;
      fgColor = scheme.onErrorContainer;
    } else if (text.contains('限选') || text.contains('任选')) {
      bgColor = scheme.tertiaryContainer;
      fgColor = scheme.onTertiaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fgColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('课程详情'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('序号', plan.index),
              _detailRow('开课学期', plan.term),
              _detailRow('课程编号', plan.courseCode),
              _detailRow('课程名称', plan.courseName),
              _detailRow('开课单位', plan.department),
              _detailRow('学分', plan.credits),
              _detailRow('总学时', plan.totalHours),
              _detailRow('考核方式', plan.examType),
              _detailRow('课程性质', plan.courseNature),
              _detailRow('课程属性', plan.courseAttr),
              _detailRow('是否考试', plan.isExam),
            ],
          ),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
