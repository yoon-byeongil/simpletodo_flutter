import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_model/todo_view_model.dart';
import 'view_model/settings_view_model.dart';
import 'view/home_view.dart';
import 'service/notification_service.dart'; // [추가]

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // [추가] 플러터 엔진 초기화 보장
  await NotificationService().init(); // [추가] 알림 서비스 시작

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

// ... MyApp 클래스는 기존과 동일 ...
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<SettingsViewModel>().isDarkMode;
    return MaterialApp(
      title: 'Simple Todo',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
