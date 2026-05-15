import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_strings.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../widgets/skeletons.dart';
import '../widgets/state_widgets.dart';

class BookDetailsDialog extends StatefulWidget {
  final ApiService apiService;
  final String bookId;
  final String currency;
  final bool isSavedBook;
  final Set<String> savedAuthorIds;
  final ValueChanged<BookListItem> onToggleSavedBook;
  final ValueChanged<AuthorSearchItem> onToggleSavedAuthor;
  final ValueChanged<String> onOpenAuthor;

  const BookDetailsDialog({
    super.key,
    required this.apiService,
    required this.bookId,
    required this.currency,
    required this.isSavedBook,
    required this.savedAuthorIds,
    required this.onToggleSavedBook,
    required this.onToggleSavedAuthor,
    required this.onOpenAuthor,
  });

  @override
  State<BookDetailsDialog> createState() => _BookDetailsDialogState();
}

class _BookDetailsDialogState extends State<BookDetailsDialog> {
  BookDetails? _details;
  bool _loading = true;
  String? _error;
  bool? _savedBookOverride;
  final Map<String, bool> _savedAuthorsOverride = <String, bool>{};

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
      final details = await widget.apiService.getBookDetails(
        bookId: widget.bookId,
        currency: widget.currency,
      );
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

  Future<void> _copyOfferUrl(String url) async {
    final strings = context.strings;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.offerUrlCopied)),
    );
  }

  Future<void> _openOfferUrl(String url) async {
    final strings = context.strings;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.invalidOfferUrl)),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.failedOpenUrl)),
      );
    }
  }

  bool _isBookSaved() => _savedBookOverride ?? widget.isSavedBook;

  bool _isAuthorSaved(String authorId) => _savedAuthorsOverride[authorId] ?? widget.savedAuthorIds.contains(authorId);

  void _toggleSavedBook(BookDetails details) {
    final nextState = !_isBookSaved();
    setState(() {
      _savedBookOverride = nextState;
    });
    widget.onToggleSavedBook(
      BookListItem(
        id: details.id,
        title: details.title,
        subtitle: details.subtitle,
        authors: details.authors.map((author) => author.name).toList(),
        coverUrl: details.coverUrl,
        language: details.language,
        genre: details.genres.isEmpty ? null : details.genres.first,
        isbn13: details.isbn13,
        offersCount: details.offers.where((offer) => offer.hasPrice).length,
        priceRange: _buildPriceRange(details.offers),
      ),
    );
  }

  void _toggleSavedAuthor(AuthorShort author) {
    final nextState = !_isAuthorSaved(author.id);
    setState(() {
      _savedAuthorsOverride[author.id] = nextState;
    });
    widget.onToggleSavedAuthor(
      AuthorSearchItem(
        id: author.id,
        name: author.name,
        birthYear: null,
        deathYear: null,
        photoUrl: null,
        booksCount: 0,
      ),
    );
  }

  PriceRange? _buildPriceRange(List<OfferItem> offers) {
    final pricedOffers = offers.where((offer) => offer.hasPrice && offer.convertedPrice != null).toList();
    if (pricedOffers.isEmpty) {
      return null;
    }
    final amounts = pricedOffers.map((offer) => offer.convertedPrice!.amount).toList()..sort();
    return PriceRange(
      min: amounts.first,
      max: amounts.last,
      currency: pricedOffers.first.convertedPrice!.currency,
    );
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
        message: strings.noBookDetailsMessage,
      );
    }

    final pricedOffers = details.offers.where((offer) => offer.hasPrice && offer.convertedPrice != null).toList();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, strings, details),
            const SizedBox(height: 18),
            if (details.authors.isNotEmpty) ...[
              Text(strings.authorsSectionTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 76),
                child: Column(
                  children: details.authors.map((author) {
                    final isSaved = _isAuthorSaved(author.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline),
                        title: Text(author.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _toggleSavedAuthor(author),
                              tooltip: isSaved ? strings.removeFromFavoritesTooltip : strings.saveToFavoritesTooltip,
                              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                            ),
                            IconButton(
                              onPressed: () => widget.onOpenAuthor(author.id),
                              tooltip: strings.openAuthorDetailsTooltip,
                              icon: const Icon(Icons.open_in_new),
                            ),
                          ],
                        ),
                        onTap: () => widget.onOpenAuthor(author.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if ((details.description ?? '').trim().isNotEmpty) ...[
              Text(strings.descriptionSectionTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildDescriptionBox(context, details.description!.trim()),
              const SizedBox(height: 16),
            ],
            Text(strings.offersTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (pricedOffers.isEmpty)
              EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: strings.noOffersTitle,
                message: strings.noOffersMessage,
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 160),
                child: Column(
                  children: pricedOffers.map((offer) {
                    final original = offer.originalPrice;
                    final converted = offer.convertedPrice;
                    final priceOriginal = original == null || original.amount <= 0
                        ? '-'
                        : '${original.amount.toStringAsFixed(2)} ${original.currency}';
                    final priceConverted = converted == null || converted.amount <= 0
                        ? '-'
                        : '${converted.amount.toStringAsFixed(2)} ${converted.currency}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(offer.source),
                        subtitle: Text(
                          '${strings.originalPriceValue(priceOriginal)}\n'
                          '${strings.convertedPriceValue(priceConverted)}\n'
                          '${strings.availabilityValue(offer.availability)}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: strings.copyOfferUrlTooltip,
                              onPressed: offer.offerUrl.isEmpty ? null : () => _copyOfferUrl(offer.offerUrl),
                              icon: const Icon(Icons.copy_outlined),
                            ),
                            IconButton(
                              tooltip: strings.openOfferTooltip,
                              onPressed: offer.offerUrl.isEmpty ? null : () => _openOfferUrl(offer.offerUrl),
                              icon: const Icon(Icons.open_in_new),
                            ),
                          ],
                        ),
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

  Widget _buildHeader(BuildContext context, AppStrings strings, BookDetails details) {
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
          child: const Icon(Icons.menu_book_outlined, size: 42),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(details.title, style: Theme.of(context).textTheme.headlineSmall),
              if ((details.subtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(details.subtitle!),
              ],
              const SizedBox(height: 8),
              Text(strings.languageValue(strings.valueOrDash(details.language))),
              Text(strings.publisherValue(strings.valueOrDash(details.publisher))),
              Text(strings.yearValue(details.publishedYear?.toString() ?? '-')),
              if ((details.isbn13 ?? '').isNotEmpty) Text('ISBN-13: ${details.isbn13}'),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _toggleSavedBook(details),
          tooltip: _isBookSaved() ? strings.removeFromFavoritesTooltip : strings.saveToFavoritesTooltip,
          icon: Icon(_isBookSaved() ? Icons.bookmark : Icons.bookmark_border),
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
