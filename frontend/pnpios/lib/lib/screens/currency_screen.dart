import 'package:flutter/material.dart';

class CurrencyScreen extends StatelessWidget {
  final String selectedCurrency;
  final List<String> currencies;
  final void Function(String currency) onSelect;

  const CurrencyScreen({
    super.key,
    required this.selectedCurrency,
    required this.currencies,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktualna waluta: $selectedCurrency',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                return Card(
                  child: RadioListTile<String>(
                    value: currency,
                    groupValue: selectedCurrency,
                    title: Text(currency),
                    onChanged: (value) {
                      if (value != null) {
                        onSelect(value);
                      }
                    },
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
