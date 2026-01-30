import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_block_service.dart';

class AdBlockSettingsPage extends StatefulWidget {
  const AdBlockSettingsPage({super.key});

  @override
  State<AdBlockSettingsPage> createState() => _AdBlockSettingsPageState();
}

class _AdBlockSettingsPageState extends State<AdBlockSettingsPage> {
  final TextEditingController _domainController = TextEditingController(text: 'https://');

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adBlockService = Provider.of<AdBlockService>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Blocked Domains',
          style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Add Domain',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _domainController,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'e.g., ads.example.com',
                            hintStyle: TextStyle(
                                color: Theme.of(context).disabledColor),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.black.withValues(alpha: 0.3) 
                              : Colors.grey.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_domainController.text.isNotEmpty) {
                              var text = _domainController.text.trim();
                              text = text.replaceAll('https://', '').replaceAll('http://', '');
                              if (text.endsWith('/')) {
                                text = text.substring(0, text.length - 1);
                              }
                              if (text.isNotEmpty) {
                                adBlockService.addDomain(text);
                                _domainController.text = 'https://';
                              }
                            }
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'BLOCKED LIST',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (adBlockService.blockedDomains.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: adBlockService.blockedDomains.map((domain) {
                  final isBlocked = adBlockService.isDomainBlocked(domain);
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.security,
                            color: isBlocked ? Colors.green : Colors.grey, 
                            size: 20),
                        title: Text(domain,
                            style: TextStyle(
                              color: isBlocked 
                                  ? Theme.of(context).textTheme.bodyLarge?.color 
                                  : Theme.of(context).disabledColor,
                              decoration: isBlocked ? null : TextDecoration.lineThrough,
                            )),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isBlocked,
                              activeThumbColor: Theme.of(context).primaryColor,
                              onChanged: (bool value) {
                                adBlockService.toggleDomainBlockedStatus(domain, value);
                              },
                            ),
                            if (!adBlockService.isDefaultDomain(domain))
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Theme.of(context).disabledColor),
                                onPressed: () => _showDeleteConfirmation(context, domain, adBlockService),
                              ),
                          ],
                        ),
                      ),
                      if (domain != adBlockService.blockedDomains.last)
                        Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    ],
                  );
                }).toList(),
              ),
            )
          else 
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No domains in block list',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String domain, AdBlockService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Remove Domain?', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Are you sure you want to remove $domain from the block list?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).disabledColor)),
          ),
          TextButton(
            onPressed: () {
              service.removeDomain(domain);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
