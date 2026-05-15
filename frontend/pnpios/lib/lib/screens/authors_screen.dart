import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/skeletons.dart';
import '../widgets/state_widgets.dart';

class AuthorsScreen extends StatefulWidget {
  final ApiService apiService;
  final LocalStorageService localStorageService;
  final Set<String> savedAuthorIds;
  final ValueChanged<AuthorSearchItem> onToggleSaved;
  final ValueChanged<String> onOpenAuthor;

  const AuthorsScreen({
    super.key,
    required this.apiService,
    required this.localStorageService,
    required this.savedAuthorIds,
    required this.onToggleSaved,
    required this.onOpenAuthor,
  });

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _nameFilterController = TextEditingController();
  final TextEditingController _minBooksController = TextEditingController();

  List<AuthorSearchItem> _items = const [];
  List<String> _history = const [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;
  bool _filtersExpanded = false;
  bool _onlySaved = false;
  bool _onlyLiving = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _nameFilterController.addListener(_refreshFilters);
    _minBooksController.addListener(_refreshFilters);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameFilterController.dispose();
    _minBooksController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await widget.localStorageService.loadAuthorSearchHistory();
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
    await widget.localStorageService.saveAuthorSearchHistory(next);
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
      final response = await widget.apiService.searchAuthors(query: effectiveQuery);
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

  List<AuthorSearchItem> get _filteredItems {
    final nameFilter = _nameFilterController.text.trim().toLowerCase();
    final minBooks = int.tryParse(_minBooksController.text.trim());

    return _items.where((item) {
      if (_onlySaved && !widget.savedAuthorIds.contains(item.id)) {
        return false;
      }
      if (_onlyLiving && item.deathYear != null) {
        return false;
      }
      if (nameFilter.isNotEmpty && !item.name.toLowerCase().contains(nameFilter)) {
        return false;
      }
      if (minBooks != null && item.booksCount < minBooks) {
        return false;
      }
      return true;
    }).toList();
  }

  void _clearFilters() {
    _nameFilterController.clear();
    _minBooksController.clear();
    setState(() {
      _onlySaved = false;
      _onlyLiving = false;
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
              strings.authorsSearchTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: strings.authorsSearchHint,
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
            Expanded(child: _buildBody(context)),
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
                  controller: _nameFilterController,
                  decoration: InputDecoration(
                    labelText: strings.nameFilterHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _minBooksController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: strings.minBooksFilterHint,
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
                label: Text(strings.onlyLivingAuthorsFilter),
                selected: _onlyLiving,
                onSelected: (value) => setState(() => _onlyLiving = value),
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
        icon: Icons.person_search_outlined,
        title: strings.noInitialResultsTitle,
        message: strings.noInitialAuthorsMessage,
      );
    }

    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: strings.noResultsTitle,
        message: strings.noAuthorsResultsMessage,
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
        final isSaved = widget.savedAuthorIds.contains(item.id);
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onOpenAuthor(item.id),
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
                    child: item.photoUrl == null || item.photoUrl!.trim().isEmpty
                        ? const Icon(Icons.person_outline)
                        : Image.network(
                            item.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person_outline),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(strings.birthDateValue(item.birthYear?.toString() ?? '-')),
                        const SizedBox(height: 4),
                        Text(strings.deathDateValue(item.deathYear?.toString() ?? '-')),
                        const SizedBox(height: 4),
                        Text(strings.booksCount(item.booksCount)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onToggleSaved(item),
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
