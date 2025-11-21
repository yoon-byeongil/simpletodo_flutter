import 'package:flutter/material.dart';
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
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS 라이트 배경색
        primaryColor: const Color(0xFF3F51B5),
        cardColor: Colors.white, // 카드 배경색
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5), brightness: Brightness.light),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
      ),

      // [다크 모드 테마] (여기를 제대로 추가했습니다)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // 완전 검정 (또는 0xFF1C1C1E)
        primaryColor: const Color(0xFF5C6BC0), // 조금 더 밝은 인디고 (다크모드용)
        cardColor: const Color(0xFF1C1C1E), // iOS 다크모드 카드색
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C6BC0), brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1C1C1E), foregroundColor: Colors.white, elevation: 0),
      ),
      home: const HomeScreen(),
    );
  }
}
