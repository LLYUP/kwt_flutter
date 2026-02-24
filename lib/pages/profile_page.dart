// 个人中心页面：展示登录状态、基本信息、学期与开始日期设置等
import 'package:flutter/material.dart';
import 'package:kwt_flutter/services/settings.dart';
import 'package:kwt_flutter/services/session_provider.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// 个人中心页（通过 SessionProvider 获取 client）
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _settings = SettingsService();
  final _termCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  bool _loggedIn = false;
  List<String> _termOptions = const [];
  bool _loadingTerms = false;
  String? _studentId;
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _termCtrl.dispose();
    _startDateCtrl.dispose();
    super.dispose();
  }

  /// 加载本地设置与登录信息
  Future<void> _load() async {
    _termCtrl.text = await _settings.getTerm() ?? '';
    _startDateCtrl.text = await _settings.getStartDate() ?? '';
    _loggedIn = await _settings.isLoggedIn();
    _studentId = await _settings.getStudentId();
    _studentName = await _settings.getStudentName();
    setState(() {});
    _loadTerms();
  }

  /// 自动保存学期与开始日期
  Future<void> _autoSave() async {
    await _settings.saveTerm(_termCtrl.text.trim());
    await _settings.saveStartDate(_startDateCtrl.text.trim());
  }

  /// 从后端拉取学期选项并设置默认值
  Future<void> _loadTerms() async {
    setState(() => _loadingTerms = true);
    try {
      final session = SessionProvider.read(context);
      final terms = await session.client.fetchTermOptions();
      if (terms.isNotEmpty) {
        _termOptions = terms;
        if (_termCtrl.text.isEmpty) {
          _termCtrl.text = terms.first;
          await _autoSave();
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingTerms = false);
    }
  }

  /// 学期选择器：后端选项优先，失败回退自由输入
  Widget _buildTermDropdown() {
    if (_loadingTerms) {
      return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_termOptions.isEmpty) {
      return TextField(
        controller: _termCtrl,
        decoration: const InputDecoration(labelText: '学期'),
        onChanged: (_) => _autoSave(),
      );
    }
    return DropdownButtonFormField<String>(
      value: _termOptions.contains(_termCtrl.text) ? _termCtrl.text : null,
      items: _termOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v == null) return;
        _termCtrl.text = v;
        _autoSave();
      },
      decoration: const InputDecoration(labelText: '学期'),
    );
  }

  /// 顶部资料卡片：显示姓名、学号与登录状态
  /// 顶部资料卡片：现代风格渐变背景与发光阴影
  Widget _buildHeaderCard() {
    final scheme = Theme.of(context).colorScheme;
    final logged = _loggedIn;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.85),
            scheme.primary.withOpacity(0.6),
            scheme.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blueAccent, size: 36),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logged
                      ? (_studentName?.isNotEmpty == true
                          ? _studentName!
                          : (_studentId?.isNotEmpty == true ? _studentId! : '已登录'))
                      : '未登录',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    logged ? (_studentId?.isNotEmpty == true ? 'ID: $_studentId' : 'ID: -') : '未登录状态',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _SectionTitle('学期与开始日期'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildTermDropdown()),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _startDateCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: '开始日期'),
                onTap: () async {
                  final now = DateTime.now();
                  final initial = DateTime.tryParse(_startDateCtrl.text.trim()) ?? now;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(now.year - 5, 1, 1),
                    lastDate: DateTime(now.year + 5, 12, 31),
                    locale: const Locale('zh', 'CN'),
                  );
                  if (picked != null) {
                    final y = picked.year.toString().padLeft(4, '0');
                    final m = picked.month.toString().padLeft(2, '0');
                    final d = picked.day.toString().padLeft(2, '0');
                    _startDateCtrl.text = '$y-$m-$d';
                    _autoSave();
                    setState(() {});
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const SizedBox(height: 24),
          _SectionTitle('关于与账户'),
          const SizedBox(height: 8),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.system_update_alt),
              title: const Text('检查更新'),
              subtitle: Text('当前版本：${AppConfig.appVersion}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _checkForUpdate,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('联系作者'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('联系作者'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _ContactRow(label: '微信', value: 'Sept_O-O'),
                        SizedBox(height: 6),
                        _ContactRow(label: 'GitHub', value: 'https://github.com/yuan-power-plus'),
                        SizedBox(height: 6),
                        _ContactRow(label: '邮箱', value: 'lly_6120@163.com'),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('关闭')),
                    ],
                  ),
                );
              },
            ),
          ),
          _ActionTile(icon: Icons.login_outlined, label: '退出登录', onTap: _doLogout),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '作者：刘先森',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 退出登录：通过 SessionProvider 统一处理
  void _doLogout() async {
    final session = SessionProvider.read(context);
    await session.logout(context);
  }

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('正在检查更新...')));
    final info = await UpdateService.fetchLatestRelease();
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    if (info == null) {
      messenger.showSnackBar(const SnackBar(content: Text('检查失败或网络异常')));
      return;
    }
    final cmp = UpdateService.compareSemver(info.latestVersion, AppConfig.appVersion);
    if (cmp <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('已是最新版本'),
          content: Text('当前版本：${AppConfig.appVersion}'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('好的')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('发现新版本 ${info.latestVersion}'),
        content: SingleChildScrollView(child: Text(info.releaseNotes.isEmpty ? '新版本发布' : info.releaseNotes)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('稍后')),
          if (info.androidApkUrl != null)
            TextButton(
              onPressed: () async {
                final Uri url = Uri.parse(info.androidApkUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('下载 APK'),
            ),
          TextButton(
            onPressed: () async {
              final Uri url = Uri.parse(info.htmlUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('前往页面'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(leading: Icon(icon), title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text('$label：', style: Theme.of(context).textTheme.bodyMedium)),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
