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
  final bool isSavedAuthor;
  final Set<String> savedBookIds;
  final ValueChanged<AuthorSearchItem> onToggleSavedAuthor;
  final ValueChanged<BookListItem> onToggleSavedBook;

  const AuthorDetailsDialog({
    super.key,
    required this.apiService,
    required this.authorId,
    required this.currency,
    required this.onOpenBook,
    required this.isSavedAuthor,
    required this.savedBookIds,
    required this.onToggleSavedAuthor,
    required this.onToggleSavedBook,
  });

  @override
  State<AuthorDetailsDialog> createState() => _AuthorDetailsDialogState();
}

class _AuthorDetailsDialogState extends State<AuthorDetailsDialog> {
  AuthorDetails? _details;
  bool _loading = true;
  String? _error;
  bool? _savedAuthorOverride;
  final Map<String, bool> _savedBooksOverride = <String, bool>{};

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
      final details = await widget.apiService.getAuthorDetails(authorId: widget.authorId, currency: widget.currency);
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

  bool _isAuthorSaved() => _savedAuthorOverride ?? widget.isSavedAuthor;

  bool _isBookSaved(String bookId) => _savedBooksOverride[bookId] ?? widget.savedBookIds.contains(bookId);

  void _toggleAuthorSaved(AuthorDetails details) {
    final nextState = !_isAuthorSaved();
    setState(() {
      _savedAuthorOverride = nextState;
    });
    widget.onToggleSavedAuthor(
      AuthorSearchItem(
        id: details.id,
        name: details.name,
        birthYear: details.birthYear,
        deathYear: details.deathYear,
        photoUrl: details.photoUrl,
        booksCount: details.books.length,
      ),
    );
  }

  void _toggleBookSaved(BookListItem item) {
    setState(() {
      _savedBooksOverride[item.id] = !_isBookSaved(item.id);
    });
    widget.onToggleSavedBook(item);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.86;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 760, maxHeight: maxHeight),
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

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, strings, details),
            const SizedBox(height: 18),
            if ((details.biography ?? '').trim().isNotEmpty) ...[
              Text(strings.descriptionSectionTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildDescriptionBox(context, details.biography!.trim()),
              const SizedBox(height: 16),
            ],
            Text(strings.authorBooksTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (details.books.isEmpty)
              EmptyState(
                icon: Icons.library_books_outlined,
                title: strings.noAuthorBooksTitle,
                message: strings.noAuthorBooksMessage,
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 180),
                child: Column(
                  children: details.books.map((book) {
                    final isSaved = _isBookSaved(book.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(book.title),
                        subtitle: Text(_bookSubtitle(strings, book)),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _toggleBookSaved(book),
                              tooltip: isSaved ? strings.removeFromFavoritesTooltip : strings.saveToFavoritesTooltip,
                              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                            ),
                            IconButton(
                              onPressed: () => widget.onOpenBook(book.id),
                              tooltip: strings.openBookDetailsTooltip,
                              icon: const Icon(Icons.open_in_new),
                            ),
                          ],
                        ),
                        onTap: () => widget.onOpenBook(book.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _bookSubtitle(AppStrings strings, BookListItem book) {
    final priceRange = book.priceRange;
    final price = priceRange == null
        ? '-'
        : '${priceRange.min.toStringAsFixed(2)} - ${priceRange.max.toStringAsFixed(2)} ${priceRange.currency}';
    return '${strings.genreValue(strings.valueOrDash(book.genre))}\n'
        '${strings.offersCount(book.offersCount)}\n'
        '${strings.priceValue(price)}';
  }

  Widget _buildHeader(BuildContext context, AppStrings strings, AuthorDetails details) {
    return Row(
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
              const SizedBox(height: 4),
              Text(strings.booksCount(details.books.length)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _toggleAuthorSaved(details),
          tooltip: _isAuthorSaved() ? strings.removeFromFavoritesTooltip : strings.saveToFavoritesTooltip,
          icon: Icon(_isAuthorSaved() ? Icons.bookmark : Icons.bookmark_border),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: strings.closeButton,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildDescriptionBox(BuildContext context, String description) {
    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Text(description),
        ),
      ),
    );
  }
}
