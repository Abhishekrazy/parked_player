
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/history_service.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _showClearHistoryDialog(context),
          ),
        ],
      ),
      body: Consumer<HistoryService>(
        builder: (context, historyService, _) {
          final history = historyService.history;
          if (history.isEmpty) {
            return const Center(child: Text('No history available'));
          }

          // Group by date
          // Simplistic approach: List with headers
          // For now, simple ListView builder with date formatting
          
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                title: Text(item.title.isNotEmpty ? item.title : item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(_formatTime(item.timestamp), style: Theme.of(context).textTheme.bodySmall),
                onTap: () {
                   // Navigate back with URL? Or launch URL?
                   // Usually clicking history opens the page.
                   // Since we are in WebView app, we might want to pop back with result or assume this page is pushed on top of WebView.
                   // If pushed on top, we can pop with result or pushReplacement.
                   // Given structure, probably pop result is best if opened from WebView.
                   Navigator.pop(context, item.url);
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays < 1) {
      return DateFormat.jm().format(timestamp); // 5:30 PM
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(timestamp); // Mon
    } else {
      return DateFormat.yMMMd().format(timestamp); // Jan 1, 2024
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Browsing Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildClearOption(context, 'Last hour', const Duration(hours: 1)),
            _buildClearOption(context, 'Last 4 hours', const Duration(hours: 4)),
            _buildClearOption(context, 'Last 24 hours', const Duration(hours: 24)),
            _buildClearOption(context, 'Last 7 days', const Duration(days: 7)),
            _buildClearOption(context, 'All time', const Duration(days: 36500)), // 100 years
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildClearOption(BuildContext context, String label, Duration duration) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Provider.of<HistoryService>(context, listen: false).clearHistorySince(duration);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cleared history for $label')));
      },
    );
  }
}
