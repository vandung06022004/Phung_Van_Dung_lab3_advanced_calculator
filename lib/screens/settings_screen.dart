import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/history_provider.dart';
import '../models/calculator_mode.dart';
import '../models/calculator_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalculatorProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    final settings = calc.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Appearance'),
          _settingTile(
            'Theme',
            trailing: DropdownButton<String>(
              value: themeProvider.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
              onChanged: (val) => themeProvider.setTheme(val!),
            ),
          ),

          const Divider(),
          _section('Calculator'),
          _settingTile(
            'Decimal Precision',
            subtitle: '${settings.decimalPrecision} places',
            trailing: DropdownButton<int>(
              value: settings.decimalPrecision,
              underline: const SizedBox(),
              items: List.generate(9, (i) => i + 2)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (val) => calc.updateSettings(settings.copyWith(decimalPrecision: val!)),
            ),
          ),
          _settingTile(
            'Angle Mode',
            subtitle: 'For scientific calculations',
            trailing: DropdownButton<AngleMode>(
              value: settings.angleMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: AngleMode.degrees, child: Text('Degrees')),
                DropdownMenuItem(value: AngleMode.radians, child: Text('Radians')),
              ],
              onChanged: (val) => calc.updateSettings(settings.copyWith(angleMode: val!)),
            ),
          ),

          const Divider(),
          _section('Feedback'),
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            value: settings.hapticFeedback,
            onChanged: (val) => calc.updateSettings(settings.copyWith(hapticFeedback: val)),
          ),
          SwitchListTile(
            title: const Text('Sound Effects'),
            value: settings.soundEffects,
            onChanged: (val) => calc.updateSettings(settings.copyWith(soundEffects: val)),
          ),

          const Divider(),
          _section('History'),
          _settingTile(
            'History Size',
            trailing: DropdownButton<int>(
              value: settings.historySize,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 25, child: Text('25')),
                DropdownMenuItem(value: 50, child: Text('50')),
                DropdownMenuItem(value: 100, child: Text('100')),
              ],
              onChanged: (val) {
                final size = val!;
                calc.updateSettings(settings.copyWith(historySize: size));
                historyProvider.setMaxSize(size);
              },
            ),
          ),
          ListTile(
            title: const Text('Clear All History', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _confirmClear(context, historyProvider),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
      );

  Widget _settingTile(String title, {String? subtitle, required Widget trailing}) =>
      ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        contentPadding: EdgeInsets.zero,
      );

  void _confirmClear(BuildContext context, HistoryProvider history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all calculation history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              history.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
