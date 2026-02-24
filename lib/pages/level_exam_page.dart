import 'package:flutter/material.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/session_provider.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// 等级考试列表页（通过 SessionProvider 获取 client）
class LevelExamPage extends StatefulWidget {
  const LevelExamPage({super.key});

  @override
  State<LevelExamPage> createState() => _LevelExamPageState();
}

class _LevelExamPageState extends State<LevelExamPage> {
  bool _busy = false;
  String? _error;
  List<ExamLevelEntry> _list = const [];
  List<ExamLevelEntry> _filteredList = const [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterData);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 过滤列表，支持按课程名与等级关键词匹配
  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredList = _list;
      } else {
        _filteredList = _list.where((entry) =>
            entry.course.toLowerCase().contains(query) ||
            entry.totalLevel.toLowerCase().contains(query) ||
            entry.writtenLevel.toLowerCase().contains(query) ||
            entry.labLevel.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = SessionProvider.read(context);
      final data = await session.safeCall(context, () =>
        session.client.fetchExamLevel(),
      );
      if (data != null) {
        setState(() {
          _list = data;
          _filteredList = data;
        });
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
        title: const Text('等级考试', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 搜索栏
          AppSearchBar(
            controller: _searchController,
            hintText: '搜索课程名称或等级...',
            onClear: _filterData,
          ),
          
          // 统计信息
          if (_filteredList.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '共找到 ${_filteredList.length} 门课程',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (_error != null) AppErrorWidget(message: _error!),

          Expanded(
            child: _busy
                ? const AppLoadingWidget()
                : _filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildExamList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyWidget(
      message: _searchController.text.isEmpty ? '暂无等级考试数据' : '未找到相关课程',
      subtitle: _searchController.text.isNotEmpty ? '尝试使用其他关键词搜索' : null,
    );
  }

  Widget _buildExamList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredList.length,
        itemBuilder: (context, index) {
          final entry = _filteredList[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Column(
            children: [
              // 课程名称头部
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  entry.course,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // 成绩详情
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 笔试和机试成绩行
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreCard(
                            '笔试',
                            entry.writtenScore,
                            entry.writtenLevel,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildScoreCard(
                            '机试',
                            entry.labScore,
                            entry.labLevel,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 总分和等级
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreCard(
                            '总分',
                            entry.totalScore,
                            entry.totalLevel,
                            Colors.blue,
                            isTotal: true,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 考试时间
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.grey[600], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '考试时间',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeInfo('开始', entry.startDate, Colors.green),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeInfo('结束', entry.endDate, Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ))));
      },
    ));
  }

  Widget _buildScoreCard(String label, String score, String level, Color color, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: isTotal ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
