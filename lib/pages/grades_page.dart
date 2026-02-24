import 'package:flutter/material.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/services/session_provider.dart';
import 'package:kwt_flutter/common/widget/detail_row.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// 成绩列表页入口组件（通过 SessionProvider 获取 client）
class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

/// 成绩页状态：承载查询条件、加载状态、错误信息与数据集
class _GradesPageState extends State<GradesPage> {
  final _termCtrl = TextEditingController();
  List<String> _termOptions = const [];
  bool _busy = false;
  String? _error;
  List<GradeEntry> _grades = const [];
  List<GradeEntry> _filteredGrades = const [];
  final TextEditingController _searchController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterData);
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _termCtrl.dispose();
    super.dispose();
  }

  /// 触发筛选流程
  void _filterData() {
    _applyFilters();
  }

  /// 根据当前搜索关键词对 [_grades] 进行过滤
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredGrades = _grades.where((grade) {
        final matchesSearch = query.isEmpty || 
            grade.courseName.toLowerCase().contains(query) ||
            grade.courseCode.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
    });
  }

  /// 根据当前选择的学期从后端加载成绩数据
  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = SessionProvider.read(context);
      final picked = _termCtrl.text.trim();
      final termParam = picked == '全部学期' ? '' : picked;
      final data = await session.safeCall(context, () =>
        session.client.fetchGradesStructured(term: termParam),
      );
      if (data != null) {
        setState(() {
          _grades = data;
          _filteredGrades = data;
        });
      }
    } catch (e) {
      setState(() => _error = '加载失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 初始化学期选项并设置默认选中项
  Future<void> _init() async {
    try {
      final session = SessionProvider.read(context);
      final terms = await session.client.fetchTermOptions();
      _termOptions = ['全部学期', ...terms];
      if (_termCtrl.text.isEmpty && terms.isNotEmpty) {
        _termCtrl.text = terms.first;
      }
    } catch (_) {}
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('课程成绩', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 查询条件区域
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '查询条件',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                child: _termOptions.isEmpty
                          ? TextField(
                              controller: _termCtrl,
                              decoration: InputDecoration(
                                labelText: '学年学期',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                              ),
                            )
                    : DropdownButtonFormField<String>(
                        value: _termOptions.contains(_termCtrl.text) ? _termCtrl.text : null,
                        items: _termOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _termCtrl.text = v ?? _termCtrl.text),
                              decoration: InputDecoration(
                                labelText: '学年学期',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _busy ? null : _load,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('查询', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 搜索区域
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '搜索',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: '搜索课程名称...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _filterData();
                                },
                                icon: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 统计信息
          if (_filteredGrades.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.green[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '共找到 ${_filteredGrades.length} 门课程',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '平均分: ${_calculateAverageScore()}',
                    style: TextStyle(
                      color: Colors.green[700],
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
                : _filteredGrades.isEmpty
                    ? _buildEmptyState()
                    : _buildGradesList(),
          ),
        ],
      ),
    );
  }

  /// 空数据占位视图
  Widget _buildEmptyState() {
    return AppEmptyWidget(
      message: _searchController.text.isEmpty ? '暂无成绩数据' : '未找到相关课程',
      subtitle: _searchController.text.isNotEmpty ? '尝试使用其他关键词搜索' : null,
    );
  }

  /// 成绩列表（卡片式设计）
  Widget _buildGradesList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredGrades.length,
        itemBuilder: (context, index) {
          final grade = _filteredGrades[index];
          final scoreColor = _getScoreColor(grade.score);
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showGradeDetail(grade),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 序号
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // 课程信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    grade.courseName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          grade.courseAttr,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '学分: ${grade.credit}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // 成绩 & GPA
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  grade.score,
                                  style: TextStyle(
                                    color: scoreColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'GPA: ${grade.gpa}',
                                    style: TextStyle(
                                      color: Colors.purple[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 弹出单条成绩详情对话框
  void _showGradeDetail(GradeEntry grade) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.grade, color: Colors.blue[600], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                grade.courseName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
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

  /// 将分数区间映射为不同颜色
  Color _getScoreColor(String score) {
    final scoreValue = double.tryParse(score) ?? 0;
    if (scoreValue >= 90) return Colors.green;
    if (scoreValue >= 80) return Colors.blue;
    if (scoreValue >= 70) return Colors.orange;
    if (scoreValue >= 60) return Colors.yellow.shade700;
    return Colors.red;
  }

  /// 计算当前过滤结果的平均分
  String _calculateAverageScore() {
    if (_filteredGrades.isEmpty) return '0.0';
    
    double total = 0;
    int count = 0;
    
    for (final grade in _filteredGrades) {
      final score = double.tryParse(grade.score);
      if (score != null) {
        total += score;
        count++;
      }
    }
    
    if (count == 0) return '0.0';
    return (total / count).toStringAsFixed(1);
  }
}
