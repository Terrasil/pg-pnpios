import 'package:flutter/material.dart';
import '../models/offer_item.dart';

class BookDetailsScreen extends StatelessWidget {
  final String title;
  final List<String> authors;
  final String? genre;
  final String? description;
  final List<OfferItem> offers;
  final VoidCallback onSave;
  final void Function(OfferItem offer) onOpenOffer;

  const BookDetailsScreen({
    super.key,
    required this.title,
    required this.authors,
    required this.genre,
    required this.description,
    required this.offers,
    required this.onSave,
    required this.onOpenOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 100,
                height: 140,
                child: Card(child: Center(child: Icon(Icons.menu_book, size: 48))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Autor: ${authors.join(', ')}'),
                    Text('Gatunek: ${genre ?? '-'}'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Zapisz'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(description ?? 'Brak opisu'),
          const SizedBox(height: 24),
          Text('Oferty', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...offers.map(
            (offer) => Card(
              child: ListTile(
                title: Text(offer.source),
                subtitle: Text(
                  'Cena oryginalna: ${offer.originalPrice.amount.toStringAsFixed(2)} ${offer.originalPrice.currency}\n'
                  'Cena po przeliczeniu: ${offer.convertedPrice.amount.toStringAsFixed(2)} ${offer.convertedPrice.currency}',
                ),
                isThreeLine: true,
                trailing: FilledButton(
                  onPressed: () => onOpenOffer(offer),
                  child: const Text('Kup'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
