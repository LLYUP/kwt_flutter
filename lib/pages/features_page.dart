// 功能聚合页：以 ElevatedButton 网格形式展示可用功能入口（对齐 schedule-getx 风格）
import 'package:flutter/material.dart';
import 'package:kwt_flutter/presentation/timetable/pages/class_timetable_page.dart';
import 'package:kwt_flutter/presentation/grades/pages/grades_page.dart';
import 'package:kwt_flutter/pages/level_exam_page.dart';
import 'package:kwt_flutter/pages/schedule_time_page.dart';
import 'package:kwt_flutter/pages/academic_calendar_page.dart';
import 'package:kwt_flutter/presentation/textbook/pages/textbook_page.dart';
import 'package:kwt_flutter/presentation/timetable/pages/classroom_timetable_page.dart';
import 'package:kwt_flutter/presentation/training_plan/pages/training_plan_page.dart';

/// 功能入口页
class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          // 课表区域标题
          _sectionTitle(context, '教务服务'),
          // 课表区域卡片
          _cardGrid(context, _scheduleCards),
          // 生活助手标题
          SliverPadding(
            padding: const EdgeInsets.only(top: 20),
            sliver: _sectionTitle(context, '生活助手'),
          ),
          // 生活助手区域卡片
          _cardGrid(context, _lifeCards),
          // 底部间距
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// 课表区域功能列表
  List<Map<String, dynamic>> get _scheduleCards => [
    {'title': '班级课表', 'icon': Icons.class_, 'page': const ClassTimetablePage()},
    {'title': '教室课表', 'icon': Icons.meeting_room, 'page': const ClassroomTimetablePage()},
    {'title': '课程成绩', 'icon': Icons.grade, 'page': const GradesPage()},
    {'title': '等级考试', 'icon': Icons.assessment, 'page': const LevelExamPage()},
    {'title': '培养方案', 'icon': Icons.account_tree, 'page': const TrainingPlanPage()},
    {'title': '教材信息', 'icon': Icons.menu_book, 'page': const TextbookPage()},
  ];

  /// 生活助手功能列表
  List<Map<String, dynamic>> get _lifeCards => [
    {'title': '作息时间', 'icon': Icons.schedule, 'page': const ScheduleTimePage()},
    {'title': '校历', 'icon': Icons.calendar_month, 'page': const AcademicCalendar()},
  ];

  /// 区域标题
  Widget _sectionTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 16),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  /// 功能卡片网格
  Widget _cardGrid(BuildContext context, List<Map<String, dynamic>> cards) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _functionCardBtn(context, cards[index]),
          childCount: cards.length,
        ),
      ),
    );
  }

  /// 功能按钮卡片（ElevatedButton 样式，对齐 schedule-getx）
  Widget _functionCardBtn(BuildContext context, Map<String, dynamic> card) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => card['page'] as Widget),
        );
      },
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            card['icon'] as IconData,
            size: 28,
            color: scheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            card['title'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
