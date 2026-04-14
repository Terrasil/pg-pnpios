import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/state_widgets.dart';

class SavedScreen extends StatefulWidget {
  final List<BookListItem> savedBooks;
  final List<AuthorSearchItem> savedAuthors;
  final String currency;
  final ValueChanged<String> onOpenBook;
  final ValueChanged<String> onOpenAuthor;
  final ValueChanged<BookListItem> onRemoveBook;
  final ValueChanged<AuthorSearchItem> onRemoveAuthor;

  const SavedScreen({
    super.key,
    required this.savedBooks,
    required this.savedAuthors,
    required this.currency,
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
            Text('Oznaczone książki i autorzy', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _filterController,
              decoration: const InputDecoration(
                hintText: 'Filtruj zapisane elementy',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _filter = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.bar_chart), text: 'Książki'),
                Tab(icon: Icon(Icons.person), text: 'Autorzy'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  filteredBooks.isEmpty
                      ? const EmptyState(
                          icon: Icons.bookmark_border,
                          title: 'Brak zapisanych książek',
                          message: 'Dodaj książki z wyników wyszukiwania.',
                        )
                      : ListView.separated(
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
                                  'Cena: ${item.priceRange == null ? '-' : '${item.priceRange!.min.toStringAsFixed(2)} - ${item.priceRange!.max.toStringAsFixed(2)} ${item.priceRange!.currency}'}',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  onPressed: () => widget.onRemoveBook(item),
                                  icon: const Icon(Icons.bookmark_remove_outlined),
                                ),
                              ),
                            );
                          },
                        ),
                  filteredAuthors.isEmpty
                      ? const EmptyState(
                          icon: Icons.bookmark_border,
                          title: 'Brak zapisanych autorów',
                          message: 'Dodaj autorów z wyników wyszukiwania.',
                        )
                      : ListView.separated(
                          itemCount: filteredAuthors.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filteredAuthors[index];
                            return Card(
                              child: ListTile(
                                onTap: () => widget.onOpenAuthor(item.id),
                                leading: const Icon(Icons.person_outline),
                                title: Text(item.name),
                                subtitle: Text('Książki: ${item.booksCount}'),
                                trailing: IconButton(
                                  onPressed: () => widget.onRemoveAuthor(item),
                                  icon: const Icon(Icons.bookmark_remove_outlined),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
