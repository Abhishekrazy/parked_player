import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'webview_page.dart';
import '../app_constants.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
      });
    }
  }

  void _openUrl(BuildContext context, String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebViewPage(url: url, title: title),
      ),
    );
  }

  Widget _buildNetworkIcon(BuildContext context, String domain) {
    const token = AppConstants.logoDevToken;
    final logoUrl = 'https://img.logo.dev/$domain?token=$token&format=png';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.public, color: Theme.of(context).disabledColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'About',
          style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          // App Icon/Logo could go here
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image.asset('assets/parked_player.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Parked Player',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          if (_version.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Version $_version',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ListTile(
            leading: _buildNetworkIcon(context, 'abhishekrazy.com'),
            title: const Text('Abhishek Razy'),
            subtitle: const Text('Built by & Website'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).disabledColor),
            onTap: () => _openUrl(context, 'https://abhishekrazy.com', 'Abhishek Razy'),
          ),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ListTile(
            leading: _buildNetworkIcon(context, 'logo.dev'),
            title: const Text('Logo.dev'),
            subtitle: const Text('Logo Service Provider'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).disabledColor),
            onTap: () => _openUrl(context, 'https://logo.dev', 'Logo.dev'),
          ),
           ListTile(
            title: const Text('Open Source Licenses'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).disabledColor),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Parked Player',
                applicationVersion: _version,
                applicationIcon: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset('assets/parked_player.png', fit: BoxFit.contain),
                ),
              );
            },
          ),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ],
      ),
    );
  }
}
