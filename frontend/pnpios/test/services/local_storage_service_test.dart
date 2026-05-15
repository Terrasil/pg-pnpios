import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/local_storage_service.dart';

void main() {
  late LocalStorageService service;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service = LocalStorageService();
  });

  test('loadState returns default application settings when storage is empty', () async {
    final state = await service.loadState();

    expect(state.selectedCurrency, 'PLN');
    expect(state.language, 'pl');
    expect(state.textScale, 1.0);
    expect(state.highContrast, isFalse);
    expect(state.savedBookIds, isEmpty);
    expect(state.savedAuthorIds, isEmpty);
  });

  test('book search history is trimmed, deduplicated case-insensitively and newest-first', () async {
    for (final query in [
      'hobbit',
      'dune',
      'foundation',
      'witcher',
      'lotr',
      'harry potter',
      'mistborn',
      'earthsea',
      'narnia',
      'neuromancer',
      'discworld',
    ]) {
      await service.addBookSearchHistory(query);
    }

    final afterDuplicate = await service.addBookSearchHistory('HOBBIT');

    expect(afterDuplicate.length, 10);
    expect(afterDuplicate.first, 'HOBBIT');
    expect(afterDuplicate.where((item) => item.toLowerCase() == 'hobbit'), hasLength(1));
    expect(afterDuplicate.contains('dune'), isFalse);
  });

  test('empty search phrase is not added to author history', () async {
    await service.addAuthorSearchHistory('Tolkien');
    final history = await service.addAuthorSearchHistory('   ');

    expect(history, ['Tolkien']);
  });
}
