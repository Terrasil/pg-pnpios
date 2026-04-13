import 'package:flutter/material.dart';
import '../models/author_list_item.dart';

class AuthorSearchScreen extends StatelessWidget {
  final List<AuthorListItem> items;
  final TextEditingController controller;
  final VoidCallback onSearch;
  final void Function(AuthorListItem item) onOpenAuthor;

  const AuthorSearchScreen({
    super.key,
    required this.items,
    required this.controller,
    required this.onSearch,
    required this.onOpenAuthor,
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
                    labelText: 'Szukaj autora',
                    hintText: 'Imię lub nazwisko',
                    prefixIcon: Icon(Icons.person_search),
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
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(item.name),
                    subtitle: Text(
                      'Lata życia: ${item.birthYear ?? '-'} - ${item.deathYear ?? ''}\n'
                      'Książki: ${item.booksCount}',
                    ),
                    isThreeLine: true,
                    onTap: () => onOpenAuthor(item),
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
