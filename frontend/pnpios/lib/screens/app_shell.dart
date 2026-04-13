import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final void Function(int index) onDestinationSelected;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Finder')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Menu')),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Książki'),
              selected: selectedIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
            ListTile(
              leading: const Icon(Icons.person_search),
              title: const Text('Autorzy'),
              selected: selectedIndex == 1,
              onTap: () => onDestinationSelected(1),
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Waluta'),
              selected: selectedIndex == 2,
              onTap: () => onDestinationSelected(2),
            ),
            ListTile(
              leading: const Icon(Icons.bookmarks),
              title: const Text('Zapisane'),
              selected: selectedIndex == 3,
              onTap: () => onDestinationSelected(3),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ustawienia'),
              selected: selectedIndex == 4,
              onTap: () => onDestinationSelected(4),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}
