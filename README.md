# Simple ToDo (シンプルToDo)

https://github.com/user-attachments/assets/54603f5f-4065-4fc4-9a79-f233fcb47a83

---

## 📌 プロジェクト概要 (프로젝트 개요)
**Flutter**と**MVVMアーキテクチャ**を用いて開発した、シンプルかつ高機能なタスク管理アプリです。
単なるリスト管理だけでなく、**ローカル通知機能**を深く実装し、Android/iOS両方のプラットフォームにおけるバックグラウンド・フォアグラウンド通知の課題を解決しました。

> **Flutter**와 **MVVM 아키텍처**를 사용하여 개발한, 심플하면서도 고기능인 할 일 관리 앱입니다. 단순한 리스트 관리를 넘어, **로컬 알림 기능**을 깊이 있게 구현하여 Android/iOS 양대 플랫폼에서의 백그라운드/포그라운드 알림 문제를 해결했습니다.

---

## 🛠 技術スタック (기술 스택)
* **Language**: Dart
* **Framework**: Flutter
* **Architecture**: MVVM (Model-View-ViewModel)
* **State Management**: Provider
* **Local Storage**: Shared Preferences
* **Notification**: flutter_local_notifications, timezone, permission_handler
* **UI/UX**: flutter_slidable, intl, cupertino_icons

---

## ✨ 主な機能 (주요 기능)

### 1. タスク管理 (태스크 관리)
* **モダンなUI**: iOSスタイルのデートピッカー(Cupertino)とモダンなカード型デザインを採用。
* **スワイプ操作**: リストをスワイプすることで、「固定(Pin)」「編集(Edit)」「削除(Delete)」が可能です。
* **並び替え**: ピン留めされたタスクが最上位に、残りは時間の早い順に自動ソートされます。

### 2. 高度な通知システム (고도화된 알림 시스템)
* **締め切りと通知の分離**: タスクの「締め切り時間」と「通知時間」を個別に設定可能。
* **正確なスケジュール**: `timezone`パッケージを使用し、アジア/東京(Asia/Tokyo)標準時で正確に通知。
* **即時通知**: 過去の時間を設定した場合、即座に通知を送信してユーザーに知らせます。

### 3. ユーザー設定 (사용자 설정)
* **ダークモード**: システム設定に関わらず、アプリ内でテーマ切り替えが可能。
* **データ管理**: 全データの初期化機能、期限切れタスクの一括削除機能。

---

## 🏗 アーキテクチャ (아키텍처)

保守性と拡張性を高めるため、**MVVMパターン**を採用しました。

* **Model**: `Todo`データクラス。JSONシリアライズを担当。
* **View**: `HomeScreen`, `SettingsScreen`。ロジックを持たず、ViewModelの状態を購読(Consumer)してUIを描画。
* **ViewModel**: `TodoViewModel`, `SettingsViewModel`。ビジネスロジック、データ加工、通知サービスの呼び出しを担当。
* **Service**: `NotificationService`。プラットフォームごとの通知権限やチャンネル設定、OSバージョンの差異を集約して管理。

> 유지보수성과 확장성을 높이기 위해 **MVVM 패턴**을 채용했습니다.
> * **Model**: 데이터 클래스. JSON 직렬화 담당.
> * **View**: 로직 없이 ViewModel의 상태를 구독하여 UI를 그림.
> * **ViewModel**: 비즈니스 로직, 데이터 가공, 알림 서비스 호출 담당.
> * **Service**: 플랫폼별 알림 권한, 채널 설정, OS 버전 차이 관리.

---

## 🔥 工夫した点・トラブルシューティング (고민한 점 & 트러블 슈팅)

### 1. Androidにおける「正確なアラーム」とReceiver登録
Android 12以上では`SCHEDULE_EXACT_ALARM`権限が必要ですが、アプリが停止していると通知が届かない問題がありました。
* **解決策**: `AndroidManifest.xml`に`ScheduledNotificationReceiver`を明示的に登録し、システムからのブロードキャストを受け取れるようにしました。また、`permission_handler`を用いて適切な権限フローを実装しました。

### 2. iOSのフォアグラウンド通知 (AppDelegate)
iOSではデフォルトで、アプリ起動中(Foreground)に通知バナーが表示されません。
* **解決策**: `AppDelegate.swift`にて`UNUserNotificationCenter`のデリゲートを設定し、`NotificationService`の初期化設定で`presentList`, `presentBanner`などを有効にすることで、アプリ使用中でも通知が確実に届くように実装しました。

### 3. 過去時間の通知処理とUX
ユーザーが誤って過去の時間を通知に設定した場合、スケジューリングが無視される問題がありました。
* **解決策**: ViewModelで現在時刻と比較し、未来なら`zonedSchedule`(予約)、過去なら`show`(即時実行)とメソッドを使い分けるロジックを実装しました。また、日時選択時に5分単位で時間をスナップさせることで、入力の利便性を向上させました。

---

## 🚀 今後の改善点 (추후 개선 사항)
* **Repositoryパターンの導入**: データアクセス層(`SharedPreferences`)をViewModelから分離し、将来的なDB変更に備える。
* **単体テスト(Unit Test)**: ViewModelのビジネスロジックに対するテストコードの作成。
