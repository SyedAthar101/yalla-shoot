import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'services/site_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Start resolving the site's current domain (remote config) right
  // away; YallaApi awaits the same future before fetching, so the
  // first load already uses the resolved base.
  SiteConfig.ensureResolved();
  runApp(const YallaShootApp());
}

class YallaShootApp extends StatelessWidget {
  const YallaShootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'يلا شوت | Yalla Shoot',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF931800),
        scaffoldBackgroundColor: const Color(0xFF0E0E13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF931800),
          secondary: Color(0xFFFFC107),
          surface: Color(0xFF1B1B24),
        ),
        appBarTheme: const AppBarTheme(
          // Transparent so AppBars can paint the red gradient themselves.
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
        fontFamily: null,
      ),
      builder: (context, child) {
        // The whole app is Arabic-first, RTL like yallah.media.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}
