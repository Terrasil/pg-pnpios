import 'package:flutter/material.dart';

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
              active: selected == AppSection.books,
              onTap: () => onSelect(AppSection.books),
            ),
            _NavButton(
              icon: Icons.person_search_outlined,
              active: selected == AppSection.authors,
              onTap: () => onSelect(AppSection.authors),
            ),
            _NavButton(
              icon: Icons.currency_exchange,
              active: selected == AppSection.currencies,
              onTap: () => onSelect(AppSection.currencies),
            ),
            _NavButton(
              icon: Icons.bookmarks_outlined,
              active: selected == AppSection.saved,
              onTap: () => onSelect(AppSection.saved),
            ),
            const Spacer(),
            _NavButton(
              icon: Icons.settings_outlined,
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
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
    );
  }
}
