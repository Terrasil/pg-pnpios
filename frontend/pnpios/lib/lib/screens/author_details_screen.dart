import 'package:flutter/material.dart';
import '../models/book_list_item.dart';

class AuthorDetailsScreen extends StatelessWidget {
  final String name;
  final String? biography;
  final List<BookListItem> books;
  final VoidCallback onSave;
  final void Function(BookListItem item) onOpenBook;

  const AuthorDetailsScreen({
    super.key,
    required this.name,
    required this.biography,
    required this.books,
    required this.onSave,
    required this.onOpenBook,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(name, style: Theme.of(context).textTheme.headlineSmall),
              ),
              IconButton(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(biography ?? 'Brak opisu autora'),
          const SizedBox(height: 24),
          Text('Książki autora', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...books.map(
            (book) => Card(
              child: ListTile(
                title: Text(book.title),
                subtitle: Text(book.authors.join(', ')),
                onTap: () => onOpenBook(book),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
