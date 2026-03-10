import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/presentation/auth/controllers/forgot_password_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _accountCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();

  @override
  void dispose() {
    _accountCtrl.dispose();
    _idCardCtrl.dispose();
    _captchaCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final success = await ref.read(forgotPasswordControllerProvider.notifier).resetPassword(
      account: _accountCtrl.text.trim(),
      idCard: _idCardCtrl.text.trim(),
      captcha: _captchaCtrl.text.trim(),
    );

    if (success && mounted) {
      _accountCtrl.clear();
      _idCardCtrl.clear();
      _captchaCtrl.clear();
      
      final msg = ref.read(forgotPasswordControllerProvider).successMessage ?? '密码重置成功';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('重置成功'),
            ],
          ),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login
              },
              child: const Text('返回登录'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('找回密码'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.lock_reset, size: 60, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                '通过身份证号重置密码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请填写您的登录账号及绑定的身份证件号。系统核实后，您的登录密码将被重置为您身份证件号的后六位。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),

              // Username
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: TextField(
                  controller: _accountCtrl,
                  decoration: InputDecoration(
                    labelText: '登录账号/学号',
                    prefixIcon: Icon(Icons.person, color: cs.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ID Card
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: TextField(
                  controller: _idCardCtrl,
                  decoration: InputDecoration(
                    labelText: '身份证件号',
                    prefixIcon: Icon(Icons.badge, color: cs.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Captcha
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: TextField(
                        controller: _captchaCtrl,
                        decoration: InputDecoration(
                          labelText: '验证码',
                          prefixIcon: Icon(Icons.security, color: cs.onSurfaceVariant),
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
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: state.captcha == null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh, color: cs.onSurfaceVariant, size: 20),
                                  const SizedBox(width: 8),
                                  Text('刷新', style: TextStyle(color: cs.onSurfaceVariant)),
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
                Container(
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
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: state.isBusy ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
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
                          '提 交',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
