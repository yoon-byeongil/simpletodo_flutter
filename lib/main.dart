import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ▼ 파일 경로와 이름이 정확해야 합니다.
import 'view_model/todo_view_model.dart';
import 'view_model/settings_view_model.dart';
import 'view/home_view.dart';

void main() {
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
    // 설정 값을 구독하여 다크모드 변경 감지
    // 여기서 에러가 난다면 import가 안 된 것입니다.
    final isDarkMode = context.watch<SettingsViewModel>().isDarkMode;

    return MaterialApp(
      title: 'Simple Todo',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(), // home_view.dart 안에 있는 클래스 이름
    );
  }
}
