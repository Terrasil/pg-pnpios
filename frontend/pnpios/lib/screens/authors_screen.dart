import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/api_service.dart';
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
  final TextEditingController _controller = TextEditingController();
  List<AuthorSearchItem> _items = const [];
  bool _loading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final response = await widget.apiService.searchAuthors(query: _controller.text.trim());
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wyszukiwanie autora',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Imię lub nazwisko autora',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
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
                      : const Icon(Icons.tune),
                  label: const Text('Szukaj'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
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
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Brak wyników startowych',
        message: 'Wpisz dane autora i rozpocznij wyszukiwanie.',
      );
    }

    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Brak wyników',
        message: 'Backend zwrócił pustą listę autorów dla tego zapytania.',
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
                        Text('Ur. ${item.birthYear?.toString() ?? '-'}  Zm. ${item.deathYear?.toString() ?? '-'}'),
                        const SizedBox(height: 4),
                        Text('Liczba książek: ${item.booksCount}'),
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
