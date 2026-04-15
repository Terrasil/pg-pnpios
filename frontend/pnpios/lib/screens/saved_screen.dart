import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/app_models.dart';
import '../widgets/skeletons.dart';
import '../widgets/state_widgets.dart';

class SavedScreen extends StatefulWidget {
  final List<BookListItem> savedBooks;
  final List<AuthorSearchItem> savedAuthors;
  final String currency;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;
  final ValueChanged<String> onOpenBook;
  final ValueChanged<String> onOpenAuthor;
  final ValueChanged<BookListItem> onRemoveBook;
  final ValueChanged<AuthorSearchItem> onRemoveAuthor;

  const SavedScreen({
    super.key,
    required this.savedBooks,
    required this.savedAuthors,
    required this.currency,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onOpenBook,
    required this.onOpenAuthor,
    required this.onRemoveBook,
    required this.onRemoveAuthor,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final filteredBooks = widget.savedBooks
        .where((item) => item.title.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
    final filteredAuthors = widget.savedAuthors
        .where((item) => item.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(strings.savedTitle, style: Theme.of(context).textTheme.headlineSmall),
                ),
                FilledButton.tonalIcon(
                  onPressed: widget.loading ? null : widget.onRefresh,
                  icon: widget.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(strings.refreshSavedButton),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _filterController,
              decoration: InputDecoration(
                hintText: strings.savedFilterHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value;
                });
              },
            ),
            const SizedBox(height: 12),
            if (widget.loading) ...[
              Text(strings.syncingSavedData),
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: const Icon(Icons.menu_book_outlined), text: strings.booksTab),
                Tab(icon: const Icon(Icons.person), text: strings.authorsTab),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBooksTab(context, filteredBooks),
                  _buildAuthorsTab(context, filteredAuthors),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBooksTab(BuildContext context, List<BookListItem> filteredBooks) {
    final strings = context.strings;

    if (widget.loading && filteredBooks.isEmpty) {
      return ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonListCard(),
      );
    }

    if (widget.error != null && filteredBooks.isEmpty) {
      return ErrorState(message: widget.error!, onRetry: widget.onRefresh);
    }

    if (filteredBooks.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border,
        title: strings.noSavedBooksTitle,
        message: strings.noSavedBooksMessage,
      );
    }

    return ListView.separated(
      itemCount: filteredBooks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = filteredBooks[index];
        return Card(
          child: ListTile(
            onTap: () => widget.onOpenBook(item.id),
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(item.title),
            subtitle: Text(
              '${item.authors.join(', ')}\n'
              '${strings.priceValue(item.priceRange == null ? '-' : '${item.priceRange!.min.toStringAsFixed(2)} - ${item.priceRange!.max.toStringAsFixed(2)} ${item.priceRange!.currency}')}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              onPressed: () => widget.onRemoveBook(item),
              icon: const Icon(Icons.bookmark_remove_outlined),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthorsTab(BuildContext context, List<AuthorSearchItem> filteredAuthors) {
    final strings = context.strings;

    if (widget.loading && filteredAuthors.isEmpty) {
      return ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonListCard(),
      );
    }

    if (widget.error != null && filteredAuthors.isEmpty) {
      return ErrorState(message: widget.error!, onRetry: widget.onRefresh);
    }

    if (filteredAuthors.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border,
        title: strings.noSavedAuthorsTitle,
        message: strings.noSavedAuthorsMessage,
      );
    }

    return ListView.separated(
      itemCount: filteredAuthors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = filteredAuthors[index];
        return Card(
          child: ListTile(
            onTap: () => widget.onOpenAuthor(item.id),
            leading: const Icon(Icons.person_outline),
            title: Text(item.name),
            subtitle: Text(strings.simpleBooksCount(item.booksCount)),
            trailing: IconButton(
              onPressed: () => widget.onRemoveAuthor(item),
              icon: const Icon(Icons.bookmark_remove_outlined),
            ),
          ),
        );
      },
    );
  }
}
