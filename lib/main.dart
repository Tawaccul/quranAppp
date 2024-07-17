import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:quranapp/l10n/app_locale.dart';
import 'package:quranapp/providers/timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quranapp/auth/pages/login.dart';
import 'package:quranapp/pages/home_page.dart';
import 'package:quranapp/screens/data_provider.dart';
import 'package:quranapp/screens/lang_provider.dart';
import 'package:quranapp/screens/profile_screen/providers.dart';
import 'package:quranapp/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MyApp(isFirstLaunch: isFirstLaunch, isLoggedIn: isLoggedIn),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  final bool isLoggedIn;

  MyApp({required this.isFirstLaunch, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => DataProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),

      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Quran App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: isFirstLaunch
                ? SplashScreen()
                : (isLoggedIn ? SplashScreen() : LoginPage()),
            locale: Locale(languageProvider.language),
           supportedLocales: [
        Locale('en', ''), 
        Locale('ru', ''), 
        Locale('ar', ''), 
        Locale('che', '')
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
            builder: (context, child) {
              return GlobalLoaderOverlay(
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
