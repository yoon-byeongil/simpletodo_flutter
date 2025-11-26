import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // [추가] 필수 import
import 'package:provider/provider.dart';
import 'view_model/todo_view_model.dart';
import 'view_model/settings_view_model.dart';
import 'view/home_view.dart';
import 'service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => TodoViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<SettingsViewModel>().isDarkMode;

    return MaterialApp(
      title: 'Simple Todo',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // [라이트 모드 테마]
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        primaryColor: const Color(0xFF3F51B5),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5), brightness: Brightness.light),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
      ),

      // [다크 모드 테마]
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF5C6BC0),
        cardColor: const Color(0xFF1C1C1E),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C6BC0), brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1C1C1E), foregroundColor: Colors.white, elevation: 0),
      ),

      // ▼▼▼ [추가] 달력 오류 해결을 위한 언어 설정 ▼▼▼
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [
        Locale('ja', 'JP'), // 일본어
        Locale('en', 'US'), // 영어 (기본값)
      ],

      // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
      home: const HomeScreen(),
    );
  }
}
