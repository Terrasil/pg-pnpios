import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../widgets/skeletons.dart';
import '../widgets/state_widgets.dart';

class CurrenciesScreen extends StatefulWidget {
  final ApiService apiService;
  final String selectedCurrency;
  final ValueChanged<String> onSelectCurrency;

  const CurrenciesScreen({
    super.key,
    required this.apiService,
    required this.selectedCurrency,
    required this.onSelectCurrency,
  });

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  List<CurrencyRateItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CurrenciesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCurrency != widget.selectedCurrency) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await widget.apiService.getCurrencies(base: widget.selectedCurrency);
      if (!mounted) return;
      setState(() {
        _items = response.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _items = const [];
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
    final strings = context.strings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.currenciesTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text('${strings.currentCurrencyLabel}: ${widget.selectedCurrency}'),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final strings = context.strings;

    if (_loading) {
      return ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonListCard(),
      );
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.currency_exchange,
        title: strings.noCurrenciesTitle,
        message: strings.noCurrenciesMessage,
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final isSelected = item.code == widget.selectedCurrency;
        return Card(
          child: RadioListTile<String>(
            value: item.code,
            groupValue: widget.selectedCurrency,
            onChanged: (value) {
              if (value != null) {
                widget.onSelectCurrency(value);
              }
            },
            title: Text(item.code.isEmpty ? strings.missingCode : item.code),
            subtitle: Text(
              '${item.name.isEmpty ? strings.missingName : item.name}\n'
              '${strings.rateLabel}: ${item.rate.toStringAsFixed(4)}   ${strings.dateLabel}: ${item.rateDate.isEmpty ? '-' : item.rateDate}',
            ),
            secondary: isSelected ? const Icon(Icons.check_circle) : const Icon(Icons.circle_outlined),
          ),
        );
      },
    );
  }
}
