import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final String selectedLanguage;
  final double textScale;
  final bool highContrast;
  final void Function(String value) onLanguageChanged;
  final void Function(double value) onTextScaleChanged;
  final void Function(bool value) onHighContrastChanged;

  const SettingsScreen({
    super.key,
    required this.selectedLanguage,
    required this.textScale,
    required this.highContrast,
    required this.onLanguageChanged,
    required this.onTextScaleChanged,
    required this.onHighContrastChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          value: selectedLanguage,
          decoration: const InputDecoration(
            labelText: 'Język',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'pl', child: Text('Polski')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) {
            if (value != null) {
              onLanguageChanged(value);
            }
          },
        ),
        const SizedBox(height: 24),
        Text('Rozmiar tekstu: ${textScale.toStringAsFixed(1)}'),
        Slider(
          min: 0.8,
          max: 1.6,
          value: textScale,
          onChanged: onTextScaleChanged,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: highContrast,
          title: const Text('Wysoki kontrast'),
          onChanged: onHighContrastChanged,
        ),
      ],
    );
  }
}
