import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwt_flutter/models/models.dart';
import 'package:kwt_flutter/presentation/auth/controllers/login_controller.dart'; 

class TextbookState {
  final bool isBusy;
  final String? error;
  final List<TextbookEntry> textbooks;
  final List<TextbookEntry> filteredTextbooks;
  final String selectedTerm;
  final List<String> termOptions;
  final String searchQuery;

  const TextbookState({
    this.isBusy = false,
    this.error,
    this.textbooks = const [],
    this.filteredTextbooks = const [],
    this.selectedTerm = '',
    this.termOptions = const [],
    this.searchQuery = '',
  });

  TextbookState copyWith({
    bool? isBusy,
    String? error,
    bool clearError = false,
    List<TextbookEntry>? textbooks,
    List<TextbookEntry>? filteredTextbooks,
    String? selectedTerm,
    List<String>? termOptions,
    String? searchQuery,
  }) {
    return TextbookState(
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      textbooks: textbooks ?? this.textbooks,
      filteredTextbooks: filteredTextbooks ?? this.filteredTextbooks,
      selectedTerm: selectedTerm ?? this.selectedTerm,
      termOptions: termOptions ?? this.termOptions,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TextbookController extends StateNotifier<TextbookState> {
  final Ref _ref;

  TextbookController(this._ref) : super(const TextbookState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final client = _ref.read(kwtClientProvider);
      if (client != null) {
        final terms = await client.fetchTermOptions();
        List<String> options = terms;
        String term = state.selectedTerm;
        if (term.isEmpty && terms.isNotEmpty) {
          term = terms.first;
        }
        state = state.copyWith(termOptions: options, selectedTerm: term);
        
        // 当有默认选中学期时，自动拉取教材数据
        if (state.selectedTerm.isNotEmpty) {
          fetchTextbooks();
        }
      }
    } catch (_) {}
  }

  void setTerm(String term) {
    state = state.copyWith(selectedTerm: term);
  }
  
  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    
    final lowerQuery = query.toLowerCase();
    final filtered = state.textbooks.where((book) {
      return lowerQuery.isEmpty || 
          book.textbookName.toLowerCase().contains(lowerQuery) ||
          book.courseName.toLowerCase().contains(lowerQuery) ||
          book.publisher.toLowerCase().contains(lowerQuery);
    }).toList();
    
    state = state.copyWith(searchQuery: query, filteredTextbooks: filtered);
  }

  Future<void> fetchTextbooks() async {
    final client = _ref.read(kwtClientProvider);
    if (client == null) {
      state = state.copyWith(error: '未登录', clearError: false);
      return;
    }

    if (state.selectedTerm.isEmpty) {
      state = state.copyWith(error: '请选择学期', clearError: false);
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final data = await client.fetchTextbooks(termId: state.selectedTerm);
      
      final lowerQuery = state.searchQuery.toLowerCase();
      final filtered = data.where((book) {
        return lowerQuery.isEmpty || 
            book.textbookName.toLowerCase().contains(lowerQuery) ||
            book.courseName.toLowerCase().contains(lowerQuery) ||
            book.publisher.toLowerCase().contains(lowerQuery);
      }).toList();
      
      state = state.copyWith(textbooks: data, filteredTextbooks: filtered, isBusy: false);
    } catch (e) {
      state = state.copyWith(error: '加载失败: $e', isBusy: false);
    }
  }
}

final textbookControllerProvider = StateNotifierProvider.autoDispose<TextbookController, TextbookState>((ref) {
  return TextbookController(ref);
});
