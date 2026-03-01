import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';
import 'package:kwt_flutter/pages/tab_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    final success = await ref.read(loginControllerProvider.notifier).login(
      _userCtrl.text.trim(),
      _passCtrl.text,
      _codeCtrl.text.trim(),
    );

    if (success && mounted) {

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TabScaffold()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听状态改变时，同步 Controller 中的历史账密到 TextField（仅初始化一次）
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (previous?.studentId == null && next.studentId != null && _userCtrl.text.isEmpty) {
        _userCtrl.text = next.studentId!;
      }
      if (previous?.password == null && next.password != null && _passCtrl.text.isEmpty) {
        _passCtrl.text = next.password!;
      }
    });

    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Column(
                children: [
                  Icon(Icons.school_rounded, size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    '轻悦校园',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '登录',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                    
                  // Network Selection
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: state.selectedNetworkEnvironment,
                      decoration: InputDecoration(
                        labelText: '网络环境',
                        prefixIcon: Icon(Icons.wifi, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'intranet', child: Text('校园网')),
                        DropdownMenuItem(value: 'internet', child: Text('外网')),
                      ],
                      onChanged: (value) {
                        if (value != null) controller.changeNetworkEnvironment(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: TextField(
                      controller: _userCtrl,
                      decoration: InputDecoration(
                        labelText: '学号',
                        prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: TextField(
                      controller: _passCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: '密码',
                        prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Remember Password checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: state.rememberPassword,
                        onChanged: (v) {
                          if (v != null) controller.toggleRememberPassword(v);
                        },
                      ),
                      const SizedBox(width: 4),
                      const Text('记住账号与密码'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Captcha
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: TextField(
                            controller: _codeCtrl,
                            decoration: InputDecoration(
                              labelText: '验证码',
                              prefixIcon: Icon(Icons.security, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: state.isBusy ? null : () => controller.fetchCaptcha(),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: state.captcha == null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                                      const SizedBox(width: 8),
                                      Text('刷新', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(state.captcha!, fit: BoxFit.contain),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Error Box
                  if (state.error != null) ...[
                    Builder(builder: (context) {
                      final cs = Theme.of(context).colorScheme;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: cs.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(state.error!, style: TextStyle(color: cs.onErrorContainer)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  
                  // Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state.isBusy ? null : _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: state.isBusy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '登录',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                '请使用您的学号和密码登录系统',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
