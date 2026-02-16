import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/ad_block_service.dart';
import 'about_page.dart';
import 'adblock_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final adBlockService = Provider.of<AdBlockService>(context);

    // Filter out restricted domains that shouldn't be shown/edited manually if complex
    // For now, custom block list is removed to simplify settings as per "Appearance" and "Privacy" structure request.
    // If user needs custom domain blocking, I will re-add it cleanly. 
    // Given the previous code just had "Theme" and "View Mode" and "Ad Blocker", I will stick to that clean UI + About.

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          // Theme Settings
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Appearance',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13, letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(themeService.themeMode.toString().split('.').last.toUpperCase()),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.brightness_high)),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.brightness_4)),
              ],
              selected: {themeService.themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                themeService.updateThemeMode(newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                selectedForegroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('View Mode'),
            trailing: SegmentedButton<ViewMode>(
              segments: const [
                ButtonSegment(value: ViewMode.grid, icon: Icon(Icons.grid_view)),
                ButtonSegment(value: ViewMode.list, icon: Icon(Icons.view_list)),
              ],
              selected: {themeService.viewMode},
              onSelectionChanged: (Set<ViewMode> newSelection) {
                themeService.updateViewMode(newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                selectedForegroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),

          // Privacy & Security
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Privacy & Security',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13, letterSpacing: 0.5,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Ad & Tracker Blocker'),
            subtitle: const Text('Block intrusive ads and tracking scripts'),
            value: adBlockService.isEnabled,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              adBlockService.toggleAdBlock(value);
            },
          ),
          SwitchListTile(
            title: const Text('Desktop Site'),
            subtitle: const Text('Request desktop version of websites'),
            value: themeService.isDesktopMode,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              themeService.toggleDesktopMode(value);
            },
          ),
          ListTile(
            title: const Text('Manage Block List'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AdBlockSettingsPage()),
              );
            },
          ),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),

          // About
           Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Information',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13, letterSpacing: 0.5,
              ),
            ),
          ),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Version, Licenses, and Credits'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
