// 个人中心页面：展示登录状态、基本信息、学期与开始日期设置等
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/presentation/profile/controllers/profile_controller.dart';
import 'package:kwt_flutter/config/app_config.dart';
import 'package:kwt_flutter/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kwt_flutter/presentation/auth/pages/login_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _termCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();

  @override
  void dispose() {
    _termCtrl.dispose();
    _startDateCtrl.dispose();
    super.dispose();
  }

  Widget _buildTermDropdown() {
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    if (state.isLoadingTerms) {
      return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (state.termOptions.isEmpty) {
      // Sync TextController with active state.
      if (_termCtrl.text != state.selectedTerm) {
        _termCtrl.text = state.selectedTerm;
      }
      return TextField(
        controller: _termCtrl,
        decoration: const InputDecoration(labelText: '学期'),
        onChanged: (v) => controller.saveTerm(v),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: state.termOptions.contains(state.selectedTerm) ? state.selectedTerm : null,
      items: state.termOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v == null) return;
        controller.saveTerm(v);
      },
      decoration: const InputDecoration(labelText: '学期'),
    );
  }

  Widget _buildHeaderCard() {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(profileControllerProvider);
    final logged = state.isLoggedIn;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.85),
            scheme.primary.withValues(alpha: 0.6),
            scheme.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 36),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logged
                      ? (state.studentName?.isNotEmpty == true
                          ? state.studentName!
                          : (state.studentId?.isNotEmpty == true ? state.studentId! : '已登录'))
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    logged ? (state.studentId?.isNotEmpty == true ? 'ID: ${state.studentId}' : 'ID: -') : '未登录状态',
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
    // Keep internal local _startDateCtrl synced
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    if (_startDateCtrl.text.isEmpty && state.selectedStartDate.isNotEmpty) {
      _startDateCtrl.text = state.selectedStartDate;
    }

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
                    final newDate = '$y-$m-$d';
                    _startDateCtrl.text = newDate;
                    controller.saveStartDate(newDate);
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const SizedBox(height: 24),
          _SectionTitle('关于与账户'),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('检查更新'),
            subtitle: Text('当前版本：${AppConfig.appVersion}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _checkForUpdate,
          ),
          ListTile(
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
          ListTile(
            leading: const Icon(Icons.login_outlined),
            title: const Text('退出登录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await controller.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已退出登录')));
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '作者：刘先森',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
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
