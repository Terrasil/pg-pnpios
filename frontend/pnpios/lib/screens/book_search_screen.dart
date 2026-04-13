import 'package:flutter/material.dart';
import '../models/book_list_item.dart';

class BookSearchScreen extends StatelessWidget {
  final List<BookListItem> items;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final void Function(BookListItem item) onOpenBook;

  const BookSearchScreen({
    super.key,
    required this.items,
    required this.controller,
    required this.onSearch,
    required this.onOpenBook,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Szukaj książki',
                    hintText: 'Tytuł, autor lub ISBN',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onSearch,
                child: const Text('Szukaj'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.authors.join(', ')}\n'
                      'Gatunek: ${item.genre ?? '-'}\n'
                      'Oferty: ${item.offersCount}',
                    ),
                    isThreeLine: true,
                    trailing: item.priceRange == null
                        ? null
                        : Text(
                            '${item.priceRange!.min.toStringAsFixed(2)} - '
                            '${item.priceRange!.max.toStringAsFixed(2)} '
                            '${item.priceRange!.currency}',
                          ),
                    onTap: () => onOpenBook(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
