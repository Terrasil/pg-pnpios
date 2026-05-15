import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/skeletons.dart';
import '../widgets/state_widgets.dart';

class BooksScreen extends StatefulWidget {
  final ApiService apiService;
  final LocalStorageService localStorageService;
  final String currency;
  final Set<String> savedBookIds;
  final ValueChanged<BookListItem> onToggleSaved;
  final ValueChanged<String> onOpenBook;

  const BooksScreen({
    super.key,
    required this.apiService,
    required this.localStorageService,
    required this.currency,
    required this.savedBookIds,
    required this.onToggleSaved,
    required this.onOpenBook,
  });

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _authorFilterController = TextEditingController();
  final TextEditingController _genreFilterController = TextEditingController();
  final TextEditingController _languageFilterController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<BookListItem> _items = const [];
  List<String> _history = const [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;
  bool _filtersExpanded = false;
  bool _onlyWithOffers = false;
  bool _onlySaved = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    for (final controller in [
      _authorFilterController,
      _genreFilterController,
      _languageFilterController,
      _minPriceController,
      _maxPriceController,
    ]) {
      controller.addListener(_refreshFilters);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _authorFilterController.dispose();
    _genreFilterController.dispose();
    _languageFilterController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
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
    final history = await widget.localStorageService.loadBookSearchHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
    });
  }

  Future<void> _rememberSearch(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final next = <String>[
      value,
      ..._history.where((item) => item.toLowerCase() != value.toLowerCase()),
    ].take(10).toList();

    setState(() {
      _history = next;
    });
    await widget.localStorageService.saveBookSearchHistory(next);
  }

  void _refreshFilters() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _search([String? query]) async {
    final effectiveQuery = (query ?? _controller.text).trim();
    if (query != null) {
      _controller.text = effectiveQuery;
    }

    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final response = await widget.apiService.searchBooks(
        query: effectiveQuery,
        currency: widget.currency,
      );
      if (!mounted) return;
      setState(() {
        _items = response.items;
      });
      await _rememberSearch(effectiveQuery);
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

  List<BookListItem> get _filteredItems {
    final authorFilter = _authorFilterController.text.trim().toLowerCase();
    final genreFilter = _genreFilterController.text.trim().toLowerCase();
    final languageFilter = _languageFilterController.text.trim().toLowerCase();
    final minPrice = _parseDouble(_minPriceController.text);
    final maxPrice = _parseDouble(_maxPriceController.text);

    return _items.where((item) {
      if (_onlyWithOffers && item.offersCount <= 0) {
        return false;
      }
      if (_onlySaved && !widget.savedBookIds.contains(item.id)) {
        return false;
      }
      if (authorFilter.isNotEmpty &&
          !item.authors.any((author) => author.toLowerCase().contains(authorFilter))) {
        return false;
      }
      if (genreFilter.isNotEmpty && !(item.genre ?? '').toLowerCase().contains(genreFilter)) {
        return false;
      }
      if (languageFilter.isNotEmpty && !(item.language ?? '').toLowerCase().contains(languageFilter)) {
        return false;
      }
      if (minPrice != null && (item.priceRange == null || item.priceRange!.max < minPrice)) {
        return false;
      }
      if (maxPrice != null && (item.priceRange == null || item.priceRange!.min > maxPrice)) {
        return false;
      }
      return true;
    }).toList();
  }

  double? _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  void _clearFilters() {
    _authorFilterController.clear();
    _genreFilterController.clear();
    _languageFilterController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() {
      _onlyWithOffers = false;
      _onlySaved = false;
    });
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
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : () => _search(),
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(strings.searchButton),
                ),
              ],
            ),
            _buildHistory(context),
            _buildFilters(context),
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

  Widget _buildHistory(BuildContext context) {
    if (_history.isEmpty) {
      return const SizedBox(height: 16);
    }
    final strings = context.strings;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.searchHistoryTitle, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _history
                .map(
                  (query) => ActionChip(
                    avatar: const Icon(Icons.history, size: 18),
                    label: Text(query),
                    onPressed: _loading ? null : () => _search(query),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final strings = context.strings;
    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: _filtersExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _filtersExpanded = expanded;
          });
        },
        leading: const Icon(Icons.tune),
        title: Text(strings.filtersTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _authorFilterController,
                  decoration: InputDecoration(
                    labelText: strings.authorFilterHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _genreFilterController,
                  decoration: InputDecoration(
                    labelText: strings.genreFilterHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _languageFilterController,
                  decoration: InputDecoration(
                    labelText: strings.languageFilterHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${strings.minPriceFilterHint} (${widget.currency})',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${strings.maxPriceFilterHint} (${widget.currency})',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: Text(strings.onlyWithOffersFilter),
                selected: _onlyWithOffers,
                onSelected: (value) => setState(() => _onlyWithOffers = value),
              ),
              FilterChip(
                label: Text(strings.onlySavedFilter),
                selected: _onlySaved,
                onSelected: (value) => setState(() => _onlySaved = value),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: Text(strings.clearFiltersButton),
              ),
            ],
          ),
        ],
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
      return ErrorState(message: _error!, onRetry: () => _search());
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

    final items = _filteredItems;
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: strings.noResultsTitle,
        message: strings.noFilteredResultsMessage,
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
                    clipBehavior: Clip.antiAlias,
                    child: item.coverUrl == null || item.coverUrl!.trim().isEmpty
                        ? const Icon(Icons.menu_book_outlined)
                        : Image.network(
                            item.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.menu_book_outlined),
                          ),
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
