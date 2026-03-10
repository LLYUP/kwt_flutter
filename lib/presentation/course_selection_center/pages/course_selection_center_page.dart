import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/course_selection_center/providers/course_selection_center_provider.dart';
import 'package:kwt_flutter/presentation/course_selection_center/pages/course_selection_detail_page.dart';

class CourseSelectionCenterPage extends ConsumerStatefulWidget {
  const CourseSelectionCenterPage({super.key});

  @override
  ConsumerState<CourseSelectionCenterPage> createState() => _CourseSelectionCenterPageState();
}

class _CourseSelectionCenterPageState extends ConsumerState<CourseSelectionCenterPage> {
  bool _isEntering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    ref.read(courseSelectionCenterProvider.notifier).fetchRounds();
  }

  Future<void> _enterSelection(CourseSelectionRoundEntry entry) async {
    if (_isEntering) return;
    setState(() => _isEntering = true);

    try {
      await ref.read(courseSelectionCenterProvider.notifier).enterSelection(entry.jrxkParam2);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CourseSelectionDetailPage(
              roundId: entry.jrxkParam2,
              roundName: entry.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('进入选课失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEntering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseSelectionCenterProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('选课中心'),
      ),
      body: _buildBody(context, state, scheme),
    );
  }

  Widget _buildBody(BuildContext context, CourseSelectionCenterState state, ColorScheme scheme) {
    if (state.isLoading && (state.rounds == null || state.rounds!.isEmpty)) {
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
            ElevatedButton(onPressed: _fetchData, child: const Text('重试')),
          ],
        ),
      );
    }

    if (state.rounds == null || state.rounds!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text('暂无选课轮次', style: TextStyle(color: scheme.outline, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(courseSelectionCenterProvider.notifier).fetchRounds(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.rounds!.length,
        itemBuilder: (context, index) {
          final entry = state.rounds![index];
          return _buildRoundCard(context, entry, scheme);
        },
      ),
    );
  }

  Widget _buildRoundCard(BuildContext context, CourseSelectionRoundEntry entry, ColorScheme scheme) {
    final isActive = _isSelectionActive(entry.timeRange);
    final hasRoundId = entry.jrxkParam2.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学期标签 + 状态
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.term,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer),
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text('进行中', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('已结束', style: TextStyle(fontSize: 12, color: scheme.outline)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 名称
            Text(entry.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // 时间
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: scheme.outline),
                const SizedBox(width: 6),
                Expanded(child: Text(entry.timeRange, style: TextStyle(fontSize: 13, color: scheme.outline))),
              ],
            ),
            // 进入选课按钮
            if (isActive && hasRoundId) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isEntering ? null : () => _enterSelection(entry),
                  icon: _isEntering
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login),
                  label: Text(_isEntering ? '正在进入...' : '进入选课'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSelectionActive(String timeRange) {
    try {
      final parts = timeRange.split('~');
      if (parts.length != 2) return false;
      final start = DateTime.tryParse(parts[0].trim());
      final end = DateTime.tryParse(parts[1].trim());
      if (start == null || end == null) return false;
      final now = DateTime.now();
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }
}
