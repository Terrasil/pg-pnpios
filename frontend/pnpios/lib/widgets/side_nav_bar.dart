import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

enum AppSection {
  books,
  authors,
  currencies,
  saved,
  settings,
}

class SideNavBar extends StatelessWidget {
  final AppSection selected;
  final ValueChanged<AppSection> onSelect;

  const SideNavBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _NavButton(
              icon: Icons.menu_book_outlined,
              label: strings.navBooks,
              active: selected == AppSection.books,
              onTap: () => onSelect(AppSection.books),
            ),
            _NavButton(
              icon: Icons.person_search_outlined,
              label: strings.navAuthors,
              active: selected == AppSection.authors,
              onTap: () => onSelect(AppSection.authors),
            ),
            _NavButton(
              icon: Icons.currency_exchange,
              label: strings.navCurrencies,
              active: selected == AppSection.currencies,
              onTap: () => onSelect(AppSection.currencies),
            ),
            _NavButton(
              icon: Icons.bookmarks_outlined,
              label: strings.navSaved,
              active: selected == AppSection.saved,
              onTap: () => onSelect(AppSection.saved),
            ),
            const Spacer(),
            _NavButton(
              icon: Icons.settings_outlined,
              label: strings.navSettings,
              active: selected == AppSection.settings,
              onTap: () => onSelect(AppSection.settings),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: active
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
