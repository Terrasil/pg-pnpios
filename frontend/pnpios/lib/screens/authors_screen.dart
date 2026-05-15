import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/skeletons.dart';
import '../widgets/state_widgets.dart';

class AuthorsScreen extends StatefulWidget {
  final ApiService apiService;
  final Set<String> savedAuthorIds;
  final ValueChanged<AuthorSearchItem> onToggleSaved;
  final ValueChanged<String> onOpenAuthor;

  const AuthorsScreen({
    super.key,
    required this.apiService,
    required this.savedAuthorIds,
    required this.onToggleSaved,
    required this.onOpenAuthor,
  });

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _nameFilterController = TextEditingController();

  List<AuthorSearchItem> _items = const [];
  List<String> _searchHistory = const [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;
  bool _onlyWithBooks = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _localStorageService.loadAuthorSearchHistory();
    if (!mounted) return;
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _saveHistory(String query) async {
    final history = await _localStorageService.addAuthorSearchHistory(query);
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
      final response = await widget.apiService.searchAuthors(query: searchQuery);
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
      _nameFilterController.clear();
      _onlyWithBooks = false;
    });
  }

  List<AuthorSearchItem> get _filteredItems {
    final nameFilter = _nameFilterController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesName = nameFilter.isEmpty || item.name.toLowerCase().contains(nameFilter);
      final matchesBooks = !_onlyWithBooks || item.booksCount > 0;
      return matchesName && matchesBooks;
    }).toList();
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
                  onPressed: _loading ? null : _search,
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
            const SizedBox(height: 10),
            _buildHistory(context),
            const SizedBox(height: 8),
            _buildFilters(context),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    final strings = context.strings;
    if (_searchHistory.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          strings.noSearchHistory,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.searchHistoryTitle, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _searchHistory
                .map(
                  (query) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(query),
                      onPressed: _loading ? null : () => _search(query),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final strings = context.strings;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(strings.filtersTitle),
        leading: const Icon(Icons.filter_alt_outlined),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          TextField(
            controller: _nameFilterController,
            decoration: InputDecoration(
              labelText: strings.nameFilterLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _onlyWithBooks,
                  onChanged: (value) {
                    setState(() {
                      _onlyWithBooks = value ?? false;
                    });
                  },
                  title: Text(strings.onlyWithBooksFilter),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
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
      return ErrorState(message: _error!, onRetry: _search);
    }

    if (!_hasSearched) {
      return EmptyState(
        icon: Icons.person_search,
        title: strings.noInitialResultsTitle,
        message: strings.noInitialAuthorsMessage,
      );
    }

    final items = _filteredItems;
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: strings.noResultsTitle,
        message: strings.noAuthorsResultsMessage,
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSaved = widget.savedAuthorIds.contains(item.id);
        return Card(
          child: ListTile(
            onTap: () => widget.onOpenAuthor(item.id),
            leading: const Icon(Icons.person_outline),
            title: Text(item.name),
            subtitle: Text(
              '${strings.birthDateValue(item.birthYear?.toString() ?? '-')}\n'
              '${strings.deathDateValue(item.deathYear?.toString() ?? '-')}\n'
              '${strings.simpleBooksCount(item.booksCount)}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              onPressed: () => widget.onToggleSaved(item),
              tooltip: isSaved ? strings.removeFromFavoritesTooltip : strings.saveToFavoritesTooltip,
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            ),
          ),
        );
      },
    );
  }
}
