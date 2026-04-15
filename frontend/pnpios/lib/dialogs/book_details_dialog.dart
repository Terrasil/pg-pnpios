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

  const BookDetailsDialog({
    super.key,
    required this.apiService,
    required this.bookId,
    required this.currency,
  });

  @override
  State<BookDetailsDialog> createState() => _BookDetailsDialogState();
}

class _BookDetailsDialogState extends State<BookDetailsDialog> {
  BookDetails? _details;
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
        message: strings.noBookDetailsMessage,
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
                  Text(strings.authorLabel(details.authors.isEmpty ? '-' : details.authors.map((e) => e.name).join(', '))),
                  Text(strings.languageValue(strings.valueOrDash(details.language))),
                  Text(strings.publisherValue(strings.valueOrDash(details.publisher))),
                  Text(strings.yearValue(details.publishedYear?.toString() ?? '-')),
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
        Text(details.description?.trim().isNotEmpty == true ? details.description! : strings.missingBookDescription),
        const SizedBox(height: 16),
        Text(strings.offersTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Expanded(
          child: details.offers.isEmpty
              ? EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: strings.noOffersTitle,
                  message: strings.noOffersMessage,
                )
              : ListView.separated(
                  itemCount: details.offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final offer = details.offers[index];
                    final priceOriginal = '${offer.originalPrice.amount.toStringAsFixed(2)} ${offer.originalPrice.currency}';
                    final priceConverted = '${offer.convertedPrice.amount.toStringAsFixed(2)} ${offer.convertedPrice.currency}';
                    return Card(
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
                  },
                ),
        ),
      ],
    );
  }
}
