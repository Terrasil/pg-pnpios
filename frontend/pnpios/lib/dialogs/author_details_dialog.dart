import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../widgets/skeletons.dart';
import '../widgets/state_widgets.dart';

class AuthorDetailsDialog extends StatefulWidget {
  final ApiService apiService;
  final String authorId;
  final String currency;
  final ValueChanged<String> onOpenBook;

  const AuthorDetailsDialog({
    super.key,
    required this.apiService,
    required this.authorId,
    required this.currency,
    required this.onOpenBook,
  });

  @override
  State<AuthorDetailsDialog> createState() => _AuthorDetailsDialogState();
}

class _AuthorDetailsDialogState extends State<AuthorDetailsDialog> {
  AuthorDetails? _details;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final details = await widget.apiService.getAuthorDetails(authorId: widget.authorId);
      if (!mounted) return;
      setState(() {
        _details = details;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final strings = context.strings;

    if (_loading) {
      return const SingleChildScrollView(child: SkeletonDialogContent());
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    final details = _details;
    if (details == null) {
      return EmptyState(
        icon: Icons.info_outline,
        title: strings.noDataTitle,
        message: strings.noAuthorDetailsMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 130,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline, size: 42),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(details.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(strings.birthDateValue(details.birthYear?.toString() ?? '-')),
                  Text(strings.deathDateValue(details.deathYear?.toString() ?? '-')),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: strings.closeButton,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(details.biography?.trim().isNotEmpty == true ? details.biography! : strings.missingAuthorDescription),
        const SizedBox(height: 16),
        Text(strings.authorBooksTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Expanded(
          child: details.books.isEmpty
              ? EmptyState(
                  icon: Icons.library_books_outlined,
                  title: strings.noAuthorBooksTitle,
                  message: strings.noAuthorBooksMessage,
                )
              : ListView.separated(
                  itemCount: details.books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final book = details.books[index];
                    return Card(
                      child: ListTile(
                        title: Text(book.title),
                        subtitle: Text(
                          '${strings.genreValue(strings.valueOrDash(book.genre))}\n'
                          '${strings.offersCount(book.offersCount)}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onOpenBook(book.id);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
