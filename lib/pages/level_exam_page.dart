import 'package:flutter/material.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/services/session_service.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';

/// 等级考试列表页（对齐 schedule-getx 的 ScoreCard 风格）
class LevelExamPage extends ConsumerStatefulWidget {
  const LevelExamPage({super.key});

  @override
  ConsumerState<LevelExamPage> createState() => _LevelExamPageState();
}

class _LevelExamPageState extends ConsumerState<LevelExamPage> {
  bool _busy = false;
  String? _error;
  List<ExamLevelEntry> _list = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = ref.read(sessionServiceProvider);
      final data = await session.safeCall(context, () =>
        session.client.fetchExamLevel(),
      );
      if (data != null) {
        setState(() => _list = data);
      }
    } catch (e) {
      setState(() => _error = '加载失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('等级考试'),
      ),
      body: _busy
          ? const AppLoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : CustomScrollView(
                  slivers: [
                    _sliverExamList(),
                    _emptyWidget(),
                  ],
                ),
    );
  }

  /// 考试列表（ScoreCard 风格）
  Widget _sliverExamList() {
    return SliverList.builder(
      itemCount: _list.length,
      itemBuilder: (context, index) {
        final entry = _list[index];
        return _ExamScoreCard(
          subjectName: entry.course,
          subTitle: '考试时间：${entry.startDate}',
          score: entry.totalScore,
          onTap: () => _showDetail(entry),
        );
      },
    );
  }

  /// 暂无数据
  Widget _emptyWidget() {
    if (_list.isEmpty && !_busy) {
      return const SliverFillRemaining(
        child: AppEmptyWidget(message: '暂无等级考试数据'),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox());
  }

  /// 考试详情弹窗（对齐 schedule-getx 的 AlertDialog 风格）
  void _showDetail(ExamLevelEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(entry.course, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('笔试成绩', entry.writtenScore),
            _detailLine('笔试等级', entry.writtenLevel),
            _detailLine('机试成绩', entry.labScore),
            _detailLine('机试等级', entry.labLevel),
            _detailLine('总分', entry.totalScore),
            _detailLine('总等级', entry.totalLevel),
            _detailLine('开始时间', entry.startDate),
            _detailLine('结束时间', entry.endDate),
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
}

/// 等级考试卡片（对齐 schedule-getx 的 ScoreCardComponent）
class _ExamScoreCard extends StatelessWidget {
  const _ExamScoreCard({
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subjectName,
                      style: TextStyle(fontSize: 15, color: scheme.onSurface),
                    ),
                    if (subTitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subTitle!,
                        style: TextStyle(color: scheme.tertiary, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
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
