# 超シンプルTodo (Super Simple ToDo)

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-green)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)

https://github.com/user-attachments/assets/630a9c8a-7136-4e11-b705-47d308d5027c

## 📌 プロジェクト概要 (프로젝트 개요)
**Flutter**と**MVVMアーキテクチャ**を用いて開発した、実用的なタスク管理アプリです。
ユーザー体験(UX)を重視したモダンなUIに加え、**ローカル通知**、**広告(AdMob)**、**課金システム(RevenueCat)**など、実際のアプリ運用に必要な機能を網羅的に実装しました。

> **Flutter**와 **MVVM 아키텍처**를 사용하여 개발한 실용적인 태스크 관리 앱입니다.
> 사용자 경험(UX)을 중시한 모던한 UI와 더불어, **로컬 알림**, **광고(AdMob)**, **결제 시스템(RevenueCat)** 등 실제 앱 운영에 필요한 기능들을 망라하여 구현했습니다.

---

## 🛠 技術スタック (기술 스택)

| Category | Packages / Tools |
| --- | --- |
| **Framework** | Flutter, Dart |
| **Architecture** | MVVM (Model-View-ViewModel) |

---

## ✨ 主な機能 (주요 기능)

### 1. タスク管理 (태스크 관리)
* **iOSスタイル日付入力**: `CupertinoDatePicker`をカスタマイズし、「年月日」順の日本語フォーマットで直感的に入力可能。
* **スワイプ操作**: リストをスワイプして「固定(Pin)」「編集(Edit)」「削除(Delete)」が可能。
* **スマート整列**: ピン留めされたタスクを最上位に、その他は時間の早い順に自動ソート。

> * **iOS 스타일 날짜 입력**: `CupertinoDatePicker`를 커스터마이징하여, '연월일' 순의 일본어 포맷으로 직관적인 입력 가능.
> * **스와이프 조작**: 리스트를 스와이프하여 '고정', '수정', '삭제' 가능.
> * **스마트 정렬**: 핀 고정된 태스크를 최상단에, 나머지는 시간순 자동 정렬.

### 2. 高度な通知システム (고도화된 알림 시스템)
* **フォアグラウンド通知**: アプリ起動中(Foreground)でも確実に通知バナーを表示するようにiOS/Androidの設定を最適化。
* **即時通知**: 過去の時間を設定した場合、即座に通知を送信してユーザーにフィードバック。
* **権限管理**: Android 12+の`SCHEDULE_EXACT_ALARM`権限やiOSの通知権限を適切に処理。

> * **포그라운드 알림**: 앱 실행 중에도 확실하게 알림 배너가 뜨도록 iOS/Android 설정 최적화.
> * **즉시 알림**: 과거 시간을 설정하면 즉시 알림을 보내 피드백 제공.
> * **권한 관리**: Android 12+의 정확한 알람 권한 및 iOS 통지 권한 적절히 처리.

### 3. 収益化モデル (BM)
* **広告バナー**: 無料ユーザー向けにGoogle AdMobバナーを表示。
* **プレミアムプラン**: サブスクリプション機能(RevenueCat)を実装。
    * 広告の非表示 (広告領域自体を削除)
    * ピン留め数の無制限化（無料版は1つまで制限）

> * **광고 배너**: 무료 유저에게 Google AdMob 배너 표시.
> * **프리미엄 플랜**: 구독 기능(RevenueCat) 구현. (광고 제거 및 핀 고정 개수 무제한 해제)

---

## 🔥 技術的な挑戦と解決 (트러블 슈팅)

### 1. iOS/Androidの通知挙動の違い (알림 거동 차이)
iOSではアプリ使用中(Foreground)に通知が表示されず、Androidでは最新OSで正確なアラーム権限が必要という課題がありました。
* **解決策**:
    * **iOS**: `UNUserNotificationCenter`のデリゲートを`AppDelegate`で設定し、`NotificationService`初期化時に`presentAlert: true`を設定することで解決。
    * **Android**: `AndroidManifest.xml`へのReceiver登録と、`permission_handler`を用いた権限要求フローを実装。

> iOS에서는 앱 사용 중 알림이 뜨지 않고, Android는 최신 OS 권한 문제가 있었습니다.
> * **해결**: iOS는 델리게이트 위임 및 초기화 설정 변경, Android는 리시버 등록 및 권한 요청 로직 구현으로 해결했습니다.

### 2. 日付入力のUX最適化 (날짜 입력 UX 최적화)
デフォルトのAndroidカレンダーとiOSルーレットが混在し、UXが統一されていない問題がありました。
* **解決策**: すべての日付選択をiOSスタイルの`CupertinoDatePicker`に統一し、`Localizations.override`を使用して「年月日」の順序と日本語表記を強制適用しました。また、分単位の選択を5分刻みにスナップさせるロジック(`normalizeToFiveMinutes`)をViewModelに実装し、入力の手間を減らしました。

> 플랫폼별로 날짜 선택 UI가 달라 UX가 통일되지 않는 문제가 있었습니다.
> * **해결**: 모든 날짜 선택을 iOS 스타일 룰렛으로 통일하고, 로케일 오버라이드를 통해 '연월일' 순서와 일본어 표기를 강제했습니다. 또한 5분 단위 스냅 로직을 구현하여 입력 편의성을 높였습니다.

---

## 📂 ディレクトリ構造 (폴더 구조)

プロジェクトは**MVVMパターン**に基づいて、役割ごとに明確に分離されています。

> 프로젝트는 **MVVM 패턴**을 기반으로, 역할에 따라 명확하게 분리되어 있습니다.

```text
lib/
│
├── const/          # 定数管理 (상수 관리)
│   ├── app_colors.dart     # カラーパレット (브랜드 컬러, 다크모드 색상)
│   └── app_strings.dart    # 日本語テキスト (일본어 텍스트 및 메시지)
│
├── model/          # データモデル (데이터 모델)
│   └── todo_model.dart     # Todoオブジェクト定義 (Todo 객체 정의)
│
├── service/        # 外部機能・API (외부 기능 및 API)
│   ├── notification_service.dart  # ローカル通知処理 (알림 권한, 채널, 스케줄링)
│   └── purchase_service.dart      # 課金システム (RevenueCat 연동)
│
├── view/           # UI画面 (화면 UI)
│   ├── widget/             # 再利用可能なウィジェット (재사용 위젯)
│   │   ├── ad_banner.dart          # 広告バナー (광고 배너)
│   │   └── todo_bottom_sheet.dart  # 入力・編集シート (입력/수정 시트)
│   │
│   ├── home_view.dart      # メイン画面 (메인 화면)
│   ├── settings_view.dart  # 設定画面 (설정 화면)
│   └── premium_view.dart   # 課金誘導画面 (프리미엄 혜택 화면)
│
├── view_model/     # ビジネスロジック (비즈니스 로직 - Provider)
│   ├── settings_view_model.dart   # 設定状態管理 (설정 값, 결제 상태 관리)
│   └── todo_view_model.dart       # Todoロジック (CRUD, 알림 호출, 데이터 저장)
│
└── main.dart       # エントリーポイント (진입점, 테마 설정)
```
---

## 🚀 今後の改善点 (추후 개선 사항)

さらなる品質向上のため、以下のアップデートを予定しています。

> 더 나은 품질 향상을 위해, 다음의 업데이트를 예정하고 있습니다.

1.  **Repositoryパターンの導入 (Repository 패턴 도입)**
    * 現在ViewModel内にある`SharedPreferences`へのアクセス処理を分離し、データ層の独立性を高めます。将来的なデータベース変更（SQLiteやFirebaseなど）に柔軟に対応できるようにします。
    * > 현재 ViewModel 내에 있는 데이터 접근 로직을 분리하여 데이터 계층의 독립성을 높이고, 추후 DB 변경에 유연하게 대응합니다.

2.  **クラウド同期 (클라우드 동기화)**
    * Firebaseなどを導入し、複数端末間でのデータ同期機能を実装します。
    * > Firebase 등을 도입하여 여러 단말기 간의 데이터 동기화 기능을 구현합니다.
