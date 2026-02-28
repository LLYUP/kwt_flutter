import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/services/kwt_client.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';
import 'package:kwt_flutter/presentation/auth/pages/login_page.dart';

class SessionService {
  final Ref ref;
  SessionService(this.ref);

  KwtClient get client {
    final c = ref.read(kwtClientProvider);
    assert(c != null, 'KwtClient is not initialized! Check if user is logged in.');
    return c!;
  }

  Future<T?> safeCall<T>(BuildContext context, Future<T> Function() action) async {
    try {
      return await action();
    } on AuthExpiredException catch (e) {
      if (context.mounted) {
        await handleAuthExpired(context, e.message);
      }
      return null;
    }
  }

  Future<void> handleAuthExpired(BuildContext context, String message) async {
    try {
      await client.clearCookies();
    } catch (_) {}
    await ref.read(settingsProvider).clearAuth();
    ref.read(kwtClientProvider.notifier).state = null;
    
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref);
});
