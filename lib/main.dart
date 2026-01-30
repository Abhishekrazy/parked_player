
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'services/ad_block_service.dart';
import 'services/theme_service.dart';
import 'services/bookmark_service.dart';
import 'services/sites_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdBlockService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => BookmarkService()),
        ChangeNotifierProvider(create: (_) => SitesService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isIncognito = themeService.isIncognito;
        final primaryColor = isIncognito ? Colors.red : Colors.lightBlue;
        final darkPrimaryColor = isIncognito ? Colors.redAccent : const Color(0xFF29B6F6);
        
        return MaterialApp(
          title: 'Parked Player',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: primaryColor,
            scaffoldBackgroundColor: isIncognito ? const Color(0xFFFFF0F0) : const Color(0xFFF5F5F5),
            appBarTheme: AppBarTheme(
              backgroundColor: isIncognito ? const Color(0xFFFFEBEE) : Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              titleTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: isIncognito ? const Color(0xFF201010) : const Color(0xFF121212),
            primaryColor: darkPrimaryColor,
            appBarTheme: AppBarTheme(
              backgroundColor: isIncognito ? const Color(0xFF2C1515) : const Color(0xFF1F1F1F),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            colorScheme: ColorScheme.dark(
              primary: darkPrimaryColor,
              secondary: isIncognito ? Colors.redAccent : const Color(0xFF03DAC6),
              surface: isIncognito ? const Color(0xFF2C1515) : const Color(0xFF1E1E1E),
            ),
            useMaterial3: true,
          ),
          home: const VideoLinksPage(),
        );
      },
    );
  }
}
