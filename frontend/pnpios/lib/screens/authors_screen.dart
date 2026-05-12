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

enum _AuthorResultsSort { nameAsc, nameDesc, birthAsc, birthDesc, booksAsc, booksDesc }

class _AuthorsScreenState extends State<AuthorsScreen> {
  final TextEditingController _controller = TextEditingController();
  final LocalStorageService _localStorageService = LocalStorageService();
  List<AuthorSearchItem> _items = const [];
  List<String> _history = const [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;
  _AuthorResultsSort _sort = _AuthorResultsSort.nameAsc;

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

  Future<void> _loadHistory() async {
    final history = await _localStorageService.loadAuthorSearchHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
    });
  }

  Future<void> _rememberSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    await _localStorageService.addAuthorSearchHistory(query);
    await _loadHistory();
  }

  List<AuthorSearchItem> _sortItems(List<AuthorSearchItem> input, _AuthorResultsSort sort) {
    final items = [...input];
    int compareStrings(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    int birthOf(AuthorSearchItem item) => item.birthYear ?? 999999;

    items.sort((a, b) {
      switch (sort) {
        case _AuthorResultsSort.nameAsc:
          return compareStrings(a.name, b.name);
        case _AuthorResultsSort.nameDesc:
          return compareStrings(b.name, a.name);
        case _AuthorResultsSort.birthAsc:
          return birthOf(a).compareTo(birthOf(b));
        case _AuthorResultsSort.birthDesc:
          return birthOf(b).compareTo(birthOf(a));
        case _AuthorResultsSort.booksAsc:
          return a.booksCount.compareTo(b.booksCount);
        case _AuthorResultsSort.booksDesc:
          return b.booksCount.compareTo(a.booksCount);
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
      final response = await widget.apiService.searchAuthors(query: _controller.text.trim());
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

  String _sortLabel(BuildContext context, _AuthorResultsSort sort) {
    final strings = context.strings;
    switch (sort) {
      case _AuthorResultsSort.nameAsc:
        return strings.sortNameAsc;
      case _AuthorResultsSort.nameDesc:
        return strings.sortNameDesc;
      case _AuthorResultsSort.birthAsc:
        return strings.sortBirthAsc;
      case _AuthorResultsSort.birthDesc:
        return strings.sortBirthDesc;
      case _AuthorResultsSort.booksAsc:
        return strings.sortBooksAsc;
      case _AuthorResultsSort.booksDesc:
        return strings.sortBooksDesc;
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
                await _localStorageService.clearAuthorSearchHistory();
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
                ..._AuthorResultsSort.values.map(
                  (sort) => RadioListTile<_AuthorResultsSort>(
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
                  _sort = _AuthorResultsSort.nameAsc;
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
              strings.authorsSearchTitle,
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
                      hintText: strings.authorsSearchHint,
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
            Expanded(child: _buildBody(context)),
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

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
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
                    child: const Icon(Icons.person_outline),
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
