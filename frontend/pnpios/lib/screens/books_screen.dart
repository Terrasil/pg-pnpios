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

class _BooksScreenState extends State<BooksScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _authorFilterController = TextEditingController();
  final TextEditingController _genreFilterController = TextEditingController();

  List<BookListItem> _items = const [];
  List<String> _searchHistory = const [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;
  bool _onlyWithOffers = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _authorFilterController.dispose();
    _genreFilterController.dispose();
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
      _searchHistory = history;
    });
  }

  Future<void> _saveHistory(String query) async {
    final history = await _localStorageService.addBookSearchHistory(query);
    if (!mounted) return;
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _search([String? query]) async {
    final searchQuery = (query ?? _controller.text).trim();
    if (query != null) {
      _controller.text = searchQuery;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }

    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final response = await widget.apiService.searchBooks(
        query: searchQuery,
        currency: widget.currency,
      );
      await _saveHistory(searchQuery);
      if (!mounted) return;
      setState(() {
        _items = response.items;
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

  void _clearFilters() {
    setState(() {
      _authorFilterController.clear();
      _genreFilterController.clear();
      _onlyWithOffers = false;
    });
  }

  bool get _hasActiveFilters {
    return _authorFilterController.text.trim().isNotEmpty ||
        _genreFilterController.text.trim().isNotEmpty ||
        _onlyWithOffers;
  }

  List<BookListItem> get _filteredItems {
    final authorFilter = _authorFilterController.text.trim().toLowerCase();
    final genreFilter = _genreFilterController.text.trim().toLowerCase();

    return _items.where((item) {
      final matchesAuthor = authorFilter.isEmpty ||
          item.authors.any((author) => author.toLowerCase().contains(authorFilter));
      final matchesGenre = genreFilter.isEmpty ||
          (item.genre ?? '').toLowerCase().contains(genreFilter);
      final matchesOffers = !_onlyWithOffers || (item.offersCount > 0 && item.priceRange != null);
      return matchesAuthor && matchesGenre && matchesOffers;
    }).toList();
  }

  Future<void> _showHistorySheet() async {
    final strings = context.strings;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.searchHistoryTitle, style: Theme.of(sheetContext).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_searchHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(strings.noSearchHistory),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchHistory.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final query = _searchHistory[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(query),
                          onTap: _loading
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  _search(query);
                                },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFiltersSheet() async {
    final strings = context.strings;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.filtersTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _authorFilterController,
                      decoration: InputDecoration(
                        labelText: strings.authorFilterLabel,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        sheetSetState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _genreFilterController,
                      decoration: InputDecoration(
                        labelText: strings.genreFilterLabel,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        sheetSetState(() {});
                      },
                    ),
                    const SizedBox(height: 4),
                    CheckboxListTile(
                      value: _onlyWithOffers,
                      onChanged: (value) {
                        setState(() {
                          _onlyWithOffers = value ?? false;
                        });
                        sheetSetState(() {});
                      },
                      title: Text(strings.onlyWithOffersFilter),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _clearFilters();
                            sheetSetState(() {});
                          },
                          icon: const Icon(Icons.clear),
                          label: Text(strings.clearFiltersButton),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(strings.closeButton),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                    decoration: InputDecoration(
                      hintText: strings.booksSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: strings.searchHistoryTitle,
                  onPressed: _loading ? null : _showHistorySheet,
                  icon: const Icon(Icons.history),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: strings.filtersTitle,
                  onPressed: _loading ? null : _showFiltersSheet,
                  icon: Icon(_hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_loading) const SizedBox(height: 8),
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

    final items = _filteredItems;
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: strings.noResultsTitle,
        message: strings.noBooksResultsMessage,
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
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
                        tooltip: isSaved ? strings.removeFromFavoritesTooltip : strings.saveToFavoritesTooltip,
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
