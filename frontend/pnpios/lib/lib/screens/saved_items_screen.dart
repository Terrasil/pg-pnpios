import 'package:flutter/material.dart';
import '../models/author_list_item.dart';
import '../models/book_list_item.dart';

class SavedItemsScreen extends StatelessWidget {
  final List<BookListItem> savedBooks;
  final List<AuthorListItem> savedAuthors;
  final void Function(BookListItem item) onOpenBook;
  final void Function(AuthorListItem item) onOpenAuthor;

  const SavedItemsScreen({
    super.key,
    required this.savedBooks,
    required this.savedAuthors,
    required this.onOpenBook,
    required this.onOpenAuthor,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Książki'),
              Tab(text: 'Autorzy'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  itemCount: savedBooks.length,
                  itemBuilder: (context, index) {
                    final item = savedBooks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(item.title),
                      subtitle: Text(item.authors.join(', ')),
                      onTap: () => onOpenBook(item),
                    );
                  },
                ),
                ListView.builder(
                  itemCount: savedAuthors.length,
                  itemBuilder: (context, index) {
                    final item = savedAuthors[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark_added),
                      title: Text(item.name),
                      subtitle: Text('Książki: ${item.booksCount}'),
                      onTap: () => onOpenAuthor(item),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
