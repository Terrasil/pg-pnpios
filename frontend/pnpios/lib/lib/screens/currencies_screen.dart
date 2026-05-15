import 'package:flutter/material.dart';

import '../core/currency_metadata.dart';
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
        final metadata = currencyMetadataByCode[item.code.toUpperCase()];
        final isSelected = item.code == widget.selectedCurrency;
        final symbol = metadata?.symbol ?? item.code;
        final displayName = item.name.isEmpty
            ? (metadata?.fallbackName ?? strings.missingName)
            : item.name;

        return Card(
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.35)
                  : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onTap: () => widget.onSelectCurrency(item.code),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    symbol,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(item.code.isEmpty ? strings.missingCode : item.code),
            subtitle: Text(
              '$displayName'
              '${strings.rateLabel}: ${item.rate.toStringAsFixed(4)}   '
              '${strings.dateLabel}: ${item.rateDate.isEmpty ? '-' : item.rateDate}',
            ),
            isThreeLine: true,
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        );
      },
    );
  }
}
