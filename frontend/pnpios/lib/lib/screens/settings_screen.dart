import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  final String selectedLanguage;
  final double textScale;
  final bool highContrast;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<double> onTextScaleChanged;
  final ValueChanged<bool> onHighContrastChanged;

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
    final strings = context.strings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(strings.settingsTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: InputDecoration(
                labelText: strings.languageLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'pl', child: Text(strings.polish)),
                DropdownMenuItem(value: 'en', child: Text(strings.english)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onLanguageChanged(value);
                }
              },
            ),
            const SizedBox(height: 28),
            Text(strings.textSizeLabel, style: Theme.of(context).textTheme.labelLarge),
            Slider(
              min: 0.8,
              max: 1.6,
              divisions: 8,
              value: textScale,
              label: textScale.toStringAsFixed(1),
              onChanged: onTextScaleChanged,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: highContrast,
              title: Text(strings.highContrastLabel),
              onChanged: onHighContrastChanged,
            ),
          ],
        ),
      ),
    );
  }
}
