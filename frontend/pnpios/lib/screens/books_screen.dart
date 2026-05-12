import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/skeletons.dart';
import '../widgets/state_widgets.dart';

class BooksScreen extends StatefulWidget {
  final ApiService apiService;
  final String currency;
  final Set<String> savedBookIds;
  final ValueChanged<BookListItem> onToggleSaved;
  final ValueChanged<String> onOpenBook;

  const BooksScreen({
    super.key,
    required this.apiService,
    required this.currency,
    required this.savedBookIds,
    required this.onToggleSaved,
    required this.onOpenBook,
  });

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

enum _BookResultsSort { titleAsc, titleDesc, priceAsc, priceDesc, offersAsc, offersDesc }

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _controller = TextEditingController();
  final LocalStorageService _localStorageService = LocalStorageService();
  List<BookListItem> _items = const [];
  List<String> _history = const [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;
  _BookResultsSort _sort = _BookResultsSort.titleAsc;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BooksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency && _hasSearched && !_loading) {
      _search();
    }
  }

  Future<void> _loadHistory() async {
    final history = await _localStorageService.loadBookSearchHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
    });
  }

  Future<void> _rememberSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    await _localStorageService.addBookSearchHistory(query);
    await _loadHistory();
  }

  List<BookListItem> _sortItems(List<BookListItem> input, _BookResultsSort sort) {
    final items = [...input];
    int compareStrings(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    double priceOf(BookListItem item) => item.priceRange?.min ?? double.infinity;

    items.sort((a, b) {
      switch (sort) {
        case _BookResultsSort.titleAsc:
          return compareStrings(a.title, b.title);
        case _BookResultsSort.titleDesc:
          return compareStrings(b.title, a.title);
        case _BookResultsSort.priceAsc:
          return priceOf(a).compareTo(priceOf(b));
        case _BookResultsSort.priceDesc:
          return priceOf(b).compareTo(priceOf(a));
        case _BookResultsSort.offersAsc:
          return a.offersCount.compareTo(b.offersCount);
        case _BookResultsSort.offersDesc:
          return b.offersCount.compareTo(a.offersCount);
      }
    });
    return items;
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final response = await widget.apiService.searchBooks(
        query: _controller.text.trim(),
        currency: widget.currency,
      );
      await _rememberSearch();
      if (!mounted) return;
      setState(() {
        _items = _sortItems(response.items, _sort);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _items = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String _sortLabel(BuildContext context, _BookResultsSort sort) {
    final strings = context.strings;
    switch (sort) {
      case _BookResultsSort.titleAsc:
        return strings.sortTitleAsc;
      case _BookResultsSort.titleDesc:
        return strings.sortTitleDesc;
      case _BookResultsSort.priceAsc:
        return strings.sortPriceAsc;
      case _BookResultsSort.priceDesc:
        return strings.sortPriceDesc;
      case _BookResultsSort.offersAsc:
        return strings.sortOffersAsc;
      case _BookResultsSort.offersDesc:
        return strings.sortOffersDesc;
    }
  }

  Future<void> _showHistoryPopup() async {
    final strings = context.strings;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.historyButton),
        content: SizedBox(
          width: 420,
          child: _history.isEmpty
              ? Text(strings.noHistoryMessage)
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final value = _history[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(value),
                      onTap: () {
                        Navigator.of(context).pop();
                        _controller.text = value;
                        _search();
                      },
                    );
                  },
                ),
        ),
        actions: [
          if (_history.isNotEmpty)
            TextButton(
              onPressed: () async {
                await _localStorageService.clearBookSearchHistory();
                if (!mounted) return;
                setState(() {
                  _history = const [];
                });
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(strings.clearHistoryButton),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.closeButton),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterPopup() async {
    final strings = context.strings;
    var tempSort = _sort;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.filterButton),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.sortLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._BookResultsSort.values.map(
                  (sort) => RadioListTile<_BookResultsSort>(
                    value: sort,
                    groupValue: tempSort,
                    title: Text(_sortLabel(context, sort)),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          tempSort = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _sort = _BookResultsSort.titleAsc;
                  _items = _sortItems(_items, _sort);
                });
                Navigator.of(dialogContext).pop();
              },
              child: Text(strings.clearButton),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _sort = tempSort;
                  _items = _sortItems(_items, _sort);
                });
                Navigator.of(dialogContext).pop();
              },
              child: Text(strings.applyButton),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.booksSearchTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: strings.booksSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: _loading ? null : _search,
                        icon: const Icon(Icons.search),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: _showHistoryPopup,
                  tooltip: strings.historyButton,
                  icon: const Icon(Icons.history),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _showFilterPopup,
                  tooltip: strings.filterButton,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final strings = context.strings;

    if (_loading) {
      return ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonListCard(),
      );
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _search);
    }

    if (!_hasSearched) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        title: strings.noInitialResultsTitle,
        message: strings.noInitialBooksMessage,
      );
    }

    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: strings.noResultsTitle,
        message: strings.noBooksResultsMessage,
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final isSaved = widget.savedBookIds.contains(item.id);
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onOpenBook(item.id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(item.authors.isEmpty ? strings.noAuthor : item.authors.join(', ')),
                        const SizedBox(height: 4),
                        Text(strings.genreValue(strings.valueOrDash(item.genre))),
                        const SizedBox(height: 4),
                        Text(strings.offersCount(item.offersCount)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.priceRange == null
                            ? '-'
                            : '${item.priceRange!.min.toStringAsFixed(2)} - ${item.priceRange!.max.toStringAsFixed(2)} ${item.priceRange!.currency}',
                        style: Theme.of(context).textTheme.labelLarge,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () => widget.onToggleSaved(item),
                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
