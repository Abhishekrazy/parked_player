import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'bookmarks_page.dart';
import 'settings_page.dart';
import 'webview_page.dart';
import '../services/theme_service.dart';
import '../services/sites_service.dart';

class VideoLinksPage extends StatefulWidget {
  const VideoLinksPage({super.key});

  @override
  State<VideoLinksPage> createState() => _VideoLinksPageState();
}

class _VideoLinksPageState extends State<VideoLinksPage> {
  
  void _showAddSiteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController(text: 'https://');
    bool preferDesktopMode = false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g., Netflix',
                    hintStyle: TextStyle(color: Theme.of(context).disabledColor),
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).disabledColor)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://netflix.com',
                    hintStyle: TextStyle(color: Theme.of(context).disabledColor),
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).disabledColor)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setDialogState) => SwitchListTile(
                    title: Text('Desktop Mode', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    subtitle: Text('Always open in desktop mode', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                    value: preferDesktopMode,
                    activeThumbColor: Theme.of(context).primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setDialogState(() {
                        preferDesktopMode = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Theme.of(context).disabledColor)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                          var url = urlController.text.trim();
                          if (!url.startsWith('http')) {
                            url = 'https://$url';
                          }
                          Provider.of<SitesService>(context, listen: false).addSite(nameController.text.trim(), url, preferDesktopMode: preferDesktopMode);
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Add', style: TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final sitesService = Provider.of<SitesService>(context);
    final isIncognito = themeService.isIncognito;

    // Determine layout based on orientation
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    // In Grid mode: 4 cols landscape, 2 cols portrait
    // In List mode: 2 cols landscape (maybe?), 1 col portrait
    final int gridCrossAxisCount = isLandscape ? 4 : 2;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSiteDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isIncognito
            ? (Theme.of(context).brightness == Brightness.dark
                ? const [Color(0xFF2C1515), Color(0xFF201010)] 
                : const [Color(0xFFFFEBEE), Color(0xFFFFCDD2)]) 
            : (Theme.of(context).brightness == Brightness.dark
                ? const [
                    Color(0xFF0F0C29),
                    Color(0xFF302B63),
                    Color(0xFF24243E),
                  ]
                : const [
                    Color(0xFFE0EAFC),
                    Color(0xFFCFDEF3),
                  ]),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: themeService.viewMode == ViewMode.grid
                ? ReorderableGridView.count(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Bottom padding for FAB
                    physics: const BouncingScrollPhysics(),
                    crossAxisCount: gridCrossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.3,
                    onReorder: sitesService.reorderSites,
                    children: sitesService.sites.map((site) {
                      return _SiteCard(
                        key: ValueKey(site.id),
                        site: site,
                        isIncognito: isIncognito,
                      );
                    }).toList(),
                  )
                : ReorderableListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                    physics: const BouncingScrollPhysics(),
                    onReorder: sitesService.reorderSites,
                    children: sitesService.sites.map((site) {
                      return _SiteListItem(
                        key: ValueKey(site.id),
                        site: site,
                        isIncognito: isIncognito,
                      );
                    }).toList(),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final SiteItem site;
  final bool isIncognito;

  const _SiteCard({
    required Key key,
    required this.site,
    required this.isIncognito,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _HoverableCard(
        name: site.name,
        url: site.url,
        iconCode: site.iconCode,
        asset: site.asset,
        type: site.type,
        colorValue: site.colorValue,
        isIncognito: isIncognito,
        isCustom: site.isCustom,
        id: site.id,
        site: site,
    );
  }
}

class _SiteListItem extends StatelessWidget {
  final SiteItem site;
  final bool isIncognito;

  const _SiteListItem({
    required Key key,
    required this.site,
    required this.isIncognito,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildIcon(context, site),
        title: Text(
          site.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        trailing: const Icon(Icons.drag_handle),
        onTap: () {
          _HoverableCardState.handleTapStatic(context, site.url, site.name, isIncognito, site.isCustom, preferDesktopMode: site.preferDesktopMode);
        },
        onLongPress: () {
            // Optional: Show context menu for delete if custom
            if (site.isCustom) {
               _showSiteOptionsSheet(context, site);
            }
        },
      ),
    );
  }
  
  Widget _buildIcon(BuildContext context, SiteItem site) {
    if (site.asset != null && site.asset!.isNotEmpty) {
      if (site.type == 'svg') {
         return SizedBox(
          width: 40,
          height: 40,
          child: ScalableImageWidget.fromSISource(
            si: ScalableImageSource.fromSvg(
              DefaultAssetBundle.of(context),
              site.asset!,
            ),
          ),
        );
      } else if (site.type == 'image') {
         return Image.network(
           site.asset!,
           width: 40,
           height: 40,
           fit: BoxFit.contain,
           errorBuilder: (c, e, s) => const Icon(Icons.public, size: 40),
         );
      } else if (site.type == 'file') {
        return Image.file(
          File(site.asset!),
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const Icon(Icons.public, size: 40),
        );
      } else {
        return Image.asset(
          site.asset!,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        );
      }
    } else if (site.iconCode != null) {
      return Icon(
        IconData(site.iconCode!, fontFamily: 'MaterialIcons'),
        size: 32,
        color: Color(site.colorValue ?? 0xFF000000),
      );
    }
    return const Icon(Icons.web);
  }
}


class _HoverableCard extends StatefulWidget {
  final String name;
  final String url;
  final int? iconCode;
  final String? asset;
  final String? type;
  final int? colorValue;
  final bool isIncognito;
  final bool isCustom;
  final String id;
  final SiteItem? site;

  const _HoverableCard({
    required this.name,
    required this.url,
    this.iconCode,
    this.asset,
    this.type,
    required this.colorValue,
    this.isIncognito = false,
    this.isCustom = false,
    required this.id,
    this.site,
  });

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  static Future<void> handleTapStatic(BuildContext context, String url, String name, bool isIncognito, bool isCustom, {bool? preferDesktopMode}) async {
    if (url == 'TOGGLE_INCOGNITO') {
      final themeService = Provider.of<ThemeService>(context, listen: false);
      themeService.toggleIncognito();
      
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: themeService.isIncognito ? Colors.redAccent : Colors.grey[800],
          content: Text(
            themeService.isIncognito
              ? 'Incognito Mode ON'
              : 'Incognito Mode OFF',
             style: const TextStyle(color: Colors.white), 
          ),
          duration: const Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    if (url == 'SETTINGS_PAGE') {
       Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
      return;
    }

    if (url == 'BOOKMARKS_PAGE') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BookmarksPage()),
      );
      return;
    }

    if (url == 'CUSTOM_URL') {
      final TextEditingController urlController = TextEditingController();
      final String? result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text('Open URL', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: TextField(
            controller: urlController,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'https://example.com',
              hintStyle: TextStyle(color: Theme.of(context).disabledColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).disabledColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).disabledColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, urlController.text),
              child: Text('Go', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        if (!context.mounted) return;
        String finalUrl = result;
        if (!finalUrl.startsWith('http')) {
          finalUrl = 'https://$finalUrl';
        }
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WebViewPage(
                    url: finalUrl, 
                    title: 'Web',
                    isIncognito: isIncognito,
                    preferDesktopMode: preferDesktopMode,
                  ),
            ),
          );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WebViewPage(
                url: url, 
                title: name,
                isIncognito: isIncognito,
                preferDesktopMode: preferDesktopMode,
              ),
        ),
      );
    }
  }

  void _handleTap() {
    handleTapStatic(context, widget.url, widget.name, widget.isIncognito, widget.isCustom, preferDesktopMode: widget.site?.preferDesktopMode);
  }

  void _showOptionsSheet() {
    if (widget.site != null) {
      _showSiteOptionsSheet(context, widget.site!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Special styling for Toggle Incognito
    final bool isIncognitoToggle = widget.url == 'TOGGLE_INCOGNITO';
    final bool isActiveIncognito = isIncognitoToggle && widget.isIncognito;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: _handleTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A).withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActiveIncognito
                     ? Colors.redAccent.withValues(alpha: 0.5)
                     : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: isActiveIncognito ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActiveIncognito
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isActiveIncognito
                            ? Colors.redAccent
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isCustom)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _showOptionsSheet,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                ),
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }



  Widget _buildIcon() {
    if (widget.asset != null && widget.asset!.isNotEmpty) {
      if (widget.type == 'svg') {
        return SizedBox(
          width: 50,
          height: 50,
          child: ScalableImageWidget.fromSISource(
            si: ScalableImageSource.fromSvg(
              DefaultAssetBundle.of(context),
              widget.asset!,
            ),
          ),
        );
      } else if (widget.type == 'image') {
         return Image.network(
           widget.asset!,
           width: 50,
           height: 50,
           fit: BoxFit.contain,
           errorBuilder: (c, e, s) => Icon(Icons.public, size: 50, color: Theme.of(context).iconTheme.color),
         );
      } else if (widget.type == 'file') {
        return Image.file(
          File(widget.asset!),
          width: 50,
          height: 50,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Icon(Icons.public, size: 50, color: Theme.of(context).iconTheme.color),
        );
      } else {
        return Image.asset(
          widget.asset!,
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        );
      }
    } else if (widget.iconCode != null) {
      return Icon(
        IconData(widget.iconCode!, fontFamily: 'MaterialIcons'),
        size: 40,
        color: Color(widget.colorValue ?? 0xFF000000),
      );
    } else {
       return Icon(
        Icons.web,
        size: 40,
        color: Theme.of(context).primaryColor,
      );
    }
  }
}

void _showEditSiteDialog(BuildContext context, SiteItem site) {
  final nameController = TextEditingController(text: site.name);
  final urlController = TextEditingController(text: site.url);
  bool preferDesktopMode = site.preferDesktopMode;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Netflix',
                  hintStyle: TextStyle(color: Theme.of(context).disabledColor),
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).disabledColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://netflix.com',
                  hintStyle: TextStyle(color: Theme.of(context).disabledColor),
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).disabledColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDialogState) => SwitchListTile(
                  title: Text('Desktop Mode', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                  subtitle: Text('Always open in desktop mode', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                  value: preferDesktopMode,
                  activeThumbColor: Theme.of(context).primaryColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setDialogState(() {
                      preferDesktopMode = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Theme.of(context).disabledColor)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                        var url = urlController.text.trim();
                        if (!url.startsWith('http')) {
                          url = 'https://$url';
                        }
                        Provider.of<SitesService>(context, listen: false).editSite(site.id, nameController.text.trim(), url, preferDesktopMode: preferDesktopMode);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Save', style: TextStyle(color: Theme.of(context).primaryColor)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showDeleteSiteDialog(BuildContext context, SiteItem site) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      scrollable: true,
      title: Text('Delete App?', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      content: Text('Remove ${site.name} from your list?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Theme.of(context).disabledColor))),
        TextButton(
          onPressed: () {
            Provider.of<SitesService>(context, listen: false).removeSite(site.id);
            Navigator.pop(context);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

void _showSiteOptionsSheet(BuildContext context, SiteItem site) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
            title: Text('Edit', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            onTap: () {
              Navigator.pop(context);
              _showEditSiteDialog(context, site);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: Text('Remove', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteSiteDialog(context, site);
            },
          ),
        ],
      ),
    ),
  );
}
