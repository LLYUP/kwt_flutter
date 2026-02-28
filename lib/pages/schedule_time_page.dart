import 'package:flutter/material.dart';

/// 作息时间展示页：使用原生组件展示课堂作息时间表
class ScheduleTimePage extends StatelessWidget {
  const ScheduleTimePage({super.key});

  // 大节数据：(大节名称, [(小节号, 开始时间, 结束时间)])
  static const List<(String, List<(int, String, String)>)> _schedule = [
    ('第一大节', [(1, '8:15', '8:55'), (2, '9:00', '9:40')]),
    ('第二大节', [(3, '9:55', '10:35'), (4, '10:40', '11:20'), (5, '11:25', '12:05')]),
    ('第三大节', [(6, '13:50', '14:30'), (7, '14:35', '15:15')]),
    ('第四大节', [(8, '15:30', '16:10'), (9, '16:15', '16:55')]),
    ('第五大节', [(10, '18:30', '19:10'), (11, '19:15', '19:55'), (12, '20:00', '20:40')]),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '作息时间',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 顶部提示卡片
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cs.onPrimaryContainer, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '课堂教学时间不区分季节，全年使用',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 每个大节卡片
          for (final (sectionName, periods) in _schedule) ...[
            _SectionCard(sectionName: sectionName, periods: periods),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// 大节卡片
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.sectionName,
    required this.periods,
  });

  final String sectionName;
  final List<(int, String, String)> periods;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 左侧大节名称
            Container(
              width: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                sectionName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
            // 右侧小节列表
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < periods.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, indent: 12, endIndent: 12, color: cs.outlineVariant),
                    _PeriodRow(
                      index: periods[i].$1,
                      startTime: periods[i].$2,
                      endTime: periods[i].$3,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个小节行
class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.index,
    required this.startTime,
    required this.endTime,
  });

  final int index;
  final String startTime;
  final String endTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // 小节标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '第$index小节',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
          const Spacer(),
          // 时间
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '$startTime - $endTime',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
