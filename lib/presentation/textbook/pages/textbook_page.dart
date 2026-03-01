import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/textbook/controllers/textbook_controller.dart';
import 'package:kwt_flutter/common/widget/detail_row.dart';
import 'package:kwt_flutter/common/widget/common_widgets.dart';

class TextbookPage extends ConsumerStatefulWidget {
  const TextbookPage({super.key});

  @override
  ConsumerState<TextbookPage> createState() => _TextbookPageState();
}

class _TextbookPageState extends ConsumerState<TextbookPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(textbookControllerProvider.notifier).fetchTextbooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(textbookControllerProvider);
    final controller = ref.read(textbookControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('教材信息'),
        actions: [
          if (state.termOptions.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.select_all_rounded, color: Theme.of(context).colorScheme.onSurface),
              onSelected: (v) {
                controller.setTerm(v);
                controller.fetchTextbooks();
              },
              itemBuilder: (_) => state.termOptions
                  .map((e) => PopupMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
        ],
      ),
      body: state.isBusy
          ? const AppLoadingWidget(message: '加载教材中...')
          : state.error != null
              ? AppErrorWidget(message: state.error!, onRetry: () => controller.fetchTextbooks())
              : CustomScrollView(
                  slivers: [
                    _sliverTextbooksList(state),
                    _emptyWidget(state),
                  ],
                ),
    );
  }

  Widget _sliverTextbooksList(TextbookState state) {
    return SliverList.builder(
      itemCount: state.filteredTextbooks.length,
      itemBuilder: (context, index) {
        final book = state.filteredTextbooks[index];
        return _TextbookCard(
          textbookName: book.textbookName,
          subTitle: '${book.courseName} | ${book.publisher}',
          price: book.price,
          onTap: () => _showTextbookDetail(book),
        );
      },
    );
  }

  Widget _emptyWidget(TextbookState state) {
    if (state.filteredTextbooks.isEmpty && !state.isBusy) {
      if (state.selectedTerm.isEmpty) {
        return const SliverFillRemaining(
          child: AppEmptyWidget(message: '请右上角选择学期获取教材'),
        );
      }
      return const SliverFillRemaining(
        child: AppEmptyWidget(message: '该学期暂无教材信息'),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox());
  }

  void _showTextbookDetail(TextbookEntry book) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(book.textbookName, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailRow(label: '课程编号', value: book.courseCode, icon: Icons.numbers),
              DetailRow(label: '课程名称', value: book.courseName, icon: Icons.class_),
              DetailRow(label: 'ISBN', value: book.isbn, icon: Icons.qr_code),
              DetailRow(label: '定价', value: '￥${book.price}', icon: Icons.attach_money),
              DetailRow(label: '版次', value: book.edition, icon: Icons.layers),
              DetailRow(label: '出版社', value: book.publisher, icon: Icons.local_library),
              DetailRow(label: '教师', value: book.teacher, icon: Icons.person),
              DetailRow(label: '开课院系', value: book.department, icon: Icons.account_balance),
              DetailRow(label: '征订状态', value: book.orderStatus, icon: Icons.inventory),
            ],
          ),
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
}

class _TextbookCard extends StatelessWidget {
  const _TextbookCard({
    required this.textbookName,
    required this.subTitle,
    required this.price,
    this.onTap,
  });

  final String textbookName;
  final String subTitle;
  final String price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      surfaceTintColor: scheme.primary,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      textbookName,
                      style: TextStyle(
                        fontSize: 15,
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subTitle,
                      style: TextStyle(
                        color: scheme.tertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  '￥$price',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
