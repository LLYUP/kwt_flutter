import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart';

class MessageNotificationState {
  final bool isLoading;
  final String? error;
  final List<MessageNotificationEntry>? results;

  const MessageNotificationState({
    this.isLoading = false,
    this.error,
    this.results,
  });

  MessageNotificationState copyWith({
    bool? isLoading,
    String? error,
    List<MessageNotificationEntry>? results,
  }) {
    return MessageNotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      results: results ?? this.results,
    );
  }
}

class MessageNotificationNotifier extends AutoDisposeNotifier<MessageNotificationState> {
  @override
  MessageNotificationState build() {
    return const MessageNotificationState();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(kwtClientProvider);
      if (client == null) {
        throw Exception('未登录，请先登录');
      }

      final results = await client.fetchMessageNotifications();

      state = state.copyWith(
        isLoading: false,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final messageNotificationProvider = AutoDisposeNotifierProvider<MessageNotificationNotifier, MessageNotificationState>(() {
  return MessageNotificationNotifier();
});
