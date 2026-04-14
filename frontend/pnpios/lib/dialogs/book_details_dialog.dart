import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    if (_loading) {
      return const SingleChildScrollView(child: SkeletonDialogContent());
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    final details = _details;
    if (details == null) {
      return const EmptyState(
        icon: Icons.info_outline,
        title: 'Brak danych',
        message: 'Backend nie zwrócił szczegółów książki.',
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
                  Text('Autor: ${details.authors.isEmpty ? '-' : details.authors.map((e) => e.name).join(', ')}'),
                  Text('Język: ${details.language ?? '-'}'),
                  Text('Wydawca: ${details.publisher ?? '-'}'),
                  Text('Rok: ${details.publishedYear?.toString() ?? '-'}'),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(details.description?.trim().isNotEmpty == true ? details.description! : 'Brak opisu książki.'),
        const SizedBox(height: 16),
        Text('Oferty', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Expanded(
          child: details.offers.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Brak ofert',
                  message: 'Backend nie zwrócił żadnych ofert dla tej książki.',
                )
              : ListView.separated(
                  itemCount: details.offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final offer = details.offers[index];
                    return Card(
                      child: ListTile(
                        title: Text(offer.source),
                        subtitle: Text(
                          'Cena oryginalna: ${offer.originalPrice.amount.toStringAsFixed(2)} ${offer.originalPrice.currency}\n'
                          'Cena po przeliczeniu: ${offer.convertedPrice.amount.toStringAsFixed(2)} ${offer.convertedPrice.currency}\n'
                          'Dostępność: ${offer.availability}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Kopiuj URL oferty',
                          onPressed: offer.offerUrl.isEmpty
                              ? null
                              : () async {
                                  await Clipboard.setData(ClipboardData(text: offer.offerUrl));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Skopiowano URL oferty')),
                                  );
                                },
                          icon: const Icon(Icons.open_in_new),
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
