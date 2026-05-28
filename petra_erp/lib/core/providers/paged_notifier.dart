import 'package:flutter_riverpod/flutter_riverpod.dart';

class PagedState<T> {
  final List<T> items;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const PagedState({
    this.items = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PagedState<T> copyWith({
    List<T>? items,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) =>
      PagedState(
        items: items ?? this.items,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

abstract class PagedNotifier<T> extends StateNotifier<PagedState<T>> {
  static const defaultPageSize = 30;

  String _lastSearch = '';
  int _offset = 0;

  PagedNotifier() : super(const PagedState());

  Future<List<T>> fetchPage({required int offset, required int pageSize, String? search});

  Future<void> refresh({String? search}) async {
    _lastSearch = search ?? '';
    _offset = 0;
    state = const PagedState(isLoadingMore: true);
    try {
      final items = await fetchPage(offset: 0, pageSize: defaultPageSize, search: _lastSearch.isEmpty ? null : _lastSearch);
      _offset = items.length;
      state = PagedState(
        items: items,
        isLoadingMore: false,
        hasMore: items.length == defaultPageSize,
      );
    } catch (e) {
      state = PagedState(isLoadingMore: false, hasMore: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final newItems = await fetchPage(offset: _offset, pageSize: defaultPageSize, search: _lastSearch.isEmpty ? null : _lastSearch);
      _offset += newItems.length;
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoadingMore: false,
        hasMore: newItems.length == defaultPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}
