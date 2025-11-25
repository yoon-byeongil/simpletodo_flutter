# Simple Todo App (Flutter + MVVM)

## 概要 (Overview)
FlutterとMVVMアーキテクチャを使用して開発した、シンプルでモダンなタスク管理アプリです。
学習の一環として、コードの可読性と保守性を高めるためにMVVMパターンを採用し、UIとロジックの分離を意識して実装しました。

## 技術スタック (Tech Stack)
- **Language**: Dart
- **Framework**: Flutter
- **Architecture**: MVVM (Model-View-ViewModel)
- **State Management**: `ChangeNotifier`, `Provider` (or basic State depending on implementation)
- **IDE**: Xcode, VS Code

## 主な機能 (Key Features)
- **タスク管理**: タスクの追加、削除、完了状態の切り替えが可能です。
- **MVVM設計**:
  - **Model**: データの構造とロジックを定義
  - **ViewModel**: 状態管理とビジネスロジックを担当
  - **View**: UIの描画のみを担当し、ロジックを含まない設計
- **モダンなUI**: ユーザー体験を考慮したシンプルで直感的なデザイン。

## 工夫した点 (Points of Effort)
- **関心事の分離**: ViewとViewModelを明確に分けることで、コードの修正や機能追加をしやすくしました。
- **シンプルなコード**: 初学者として、まずは基本に忠実で理解しやすいコード記述を心がけました。

## 今後の課題 (Future Improvements)
- データの永続化 (SharedPreferencesやSQLiteの導入)
- タスクの編集機能の追加


https://github.com/user-attachments/assets/463a8cdb-9cc7-4138-8a8b-c59cc02f0185


