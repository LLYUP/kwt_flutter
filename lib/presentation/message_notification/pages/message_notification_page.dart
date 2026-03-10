import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/presentation/message_notification/providers/message_notification_provider.dart';

class MessageNotificationPage extends ConsumerStatefulWidget {
  const MessageNotificationPage({super.key});

  @override
  ConsumerState<MessageNotificationPage> createState() => _MessageNotificationPageState();
}

class _MessageNotificationPageState extends ConsumerState<MessageNotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    ref.read(messageNotificationProvider.notifier).fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageNotificationProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: state.isLoading ? null : _fetchData,
          ),
        ],
      ),
      body: _buildBody(context, state, scheme),
    );
  }

  Widget _buildBody(BuildContext context, MessageNotificationState state, ColorScheme scheme) {
    if (state.isLoading && (state.results == null || state.results!.isEmpty)) {
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
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.results == null || state.results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text('暂无消息通知', style: TextStyle(color: scheme.outline, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(messageNotificationProvider.notifier).fetchNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: state.results!.length,
        itemBuilder: (context, index) {
          final entry = state.results![index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.notifications_active,
                  color: scheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: Text(
                entry.businessName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(entry.content),
                  const SizedBox(height: 4),
                  Text(
                    entry.pushTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
