import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../const/app_strings.dart';
import '../../const/app_colors.dart';
import '../../view_model/settings_view_model.dart';
import '../../view_model/todo_view_model.dart';

class TodoBottomSheet extends StatefulWidget {
  final String initialTitle;
  final DateTime initialDue;
  final DateTime? initialReminder;
  final Function(String title, DateTime due, DateTime? reminder) onSaved;

  const TodoBottomSheet({super.key, required this.initialTitle, required this.initialDue, required this.initialReminder, required this.onSaved});

  @override
  State<TodoBottomSheet> createState() => _TodoBottomSheetState();
}

class _TodoBottomSheetState extends State<TodoBottomSheet> {
  late TextEditingController _textController;
  late DateTime _deadlineDate;
  bool _isReminderEnabled = false;
  late DateTime _reminderDate;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialTitle);

    // 초기값 할당
    _deadlineDate = widget.initialDue;

    if (widget.initialReminder != null) {
      _isReminderEnabled = true;
      _reminderDate = widget.initialReminder!;
    } else {
      _isReminderEnabled = false;
      _reminderDate = DateTime.now();
    }
  }

  // [수정] 날짜 선택: iOS 스타일 룰렛 (연-월-일 순서)
  void _pickDate(bool isDeadline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime initial = isDeadline ? _deadlineDate : _reminderDate;
    final todoVM = context.read<TodoViewModel>();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 250,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        child: Column(
          children: [
            // 상단 바 (완료 버튼)
            Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text(AppStrings.done, style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // 룰렛 영역
            Expanded(
              child: Localizations.override(
                context: context,
                locale: const Locale('ja'), // 일본어 강제 (년월일 표시)
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date, // 날짜만 선택
                  initialDateTime: initial,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime(2100),
                  // [핵심] 연-월-일 순서 강제 (iOS 스타일)
                  dateOrder: DatePickerDateOrder.ymd,
                  use24hFormat: true,
                  onDateTimeChanged: (newDate) {
                    setState(() {
                      if (isDeadline) {
                        // 날짜만 변경 (시간 유지)
                        _deadlineDate = todoVM.applyNewDate(_deadlineDate, newDate);
                      } else {
                        _reminderDate = todoVM.applyNewDate(_reminderDate, newDate);
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [유지] 시간 선택: iOS 스타일 룰렛 (5분 단위)
  void _pickTime(bool isDeadline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todoVM = context.read<TodoViewModel>();

    DateTime initial = isDeadline ? _deadlineDate : _reminderDate;
    // 5분 단위 보정
    initial = todoVM.normalizeToFiveMinutes(initial);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 250,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        child: Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text(AppStrings.done, style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time, // 시간만 선택
                initialDateTime: initial,
                minuteInterval: 5, // 5분 단위
                use24hFormat: true,
                onDateTimeChanged: (newTime) {
                  setState(() {
                    if (isDeadline) {
                      // 시간만 변경 (날짜 유지)
                      _deadlineDate = todoVM.applyNewTime(_deadlineDate, newTime);
                    } else {
                      _reminderDate = todoVM.applyNewTime(_reminderDate, newTime);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGlobalNotiOn = context.watch<SettingsViewModel>().isNotificationOn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: 650,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _textController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: AppStrings.addTaskHint, border: InputBorder.none),
          ),
          const Divider(),
          const SizedBox(height: 10),

          const Text(
            AppStrings.deadline,
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => _pickDate(true), // iOS 룰렛 호출
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(DateFormat('yyyy/MM/dd').format(_deadlineDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => _pickTime(true), // iOS 룰렛 호출
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(DateFormat('HH:mm').format(_deadlineDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.notificationSetting,
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Switch.adaptive(
                value: _isReminderEnabled,
                onChanged: (val) {
                  setState(() {
                    _isReminderEnabled = val;
                    if (val) {
                      final todoVM = context.read<TodoViewModel>();
                      _reminderDate = todoVM.normalizeToFiveMinutes(DateTime.now());
                    }
                  });
                },
              ),
            ],
          ),

          if (_isReminderEnabled) ...[
            if (!isGlobalNotiOn)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(AppStrings.msgNotiOff, style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
              ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _pickDate(false), // iOS 룰렛
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.notification),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.notification.withOpacity(0.05),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: AppColors.notification, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy/MM/dd').format(_reminderDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.notification),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _pickTime(false), // iOS 룰렛
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.notification),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.notification.withOpacity(0.05),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, color: AppColors.notification, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(_reminderDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.notification),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                widget.onSaved(_textController.text, _deadlineDate, _isReminderEnabled ? _reminderDate : null);
                Navigator.pop(context);
              },
              child: const Text(AppStrings.save, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
