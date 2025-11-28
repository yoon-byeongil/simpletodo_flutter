import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 필수
import 'package:intl/intl.dart';

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

    // 초기값 5분 단위 보정
    _deadlineDate = _getNearestFiveMinuteInterval(widget.initialDue);

    if (widget.initialReminder != null) {
      _isReminderEnabled = true;
      _reminderDate = _getNearestFiveMinuteInterval(widget.initialReminder!);
    } else {
      _isReminderEnabled = false;
      _reminderDate = _getNearestFiveMinuteInterval(DateTime.now());
    }
  }

  DateTime _getNearestFiveMinuteInterval(DateTime time) {
    int minute = time.minute;
    int remainder = minute % 5;
    int add = (remainder == 0) ? 0 : (5 - remainder);
    return time.add(Duration(minutes: add)).copyWith(second: 0, millisecond: 0);
  }

  // [수정된 날짜 선택기] iOS 스타일 룰렛 + 일본어(년월일) + 순서(YMD)
  void _pickDate(bool isDeadline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime initial = isDeadline ? _deadlineDate : _reminderDate;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 250,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        child: Column(
          children: [
            // 상단 완료 버튼바
            Container(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text("完了", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // 룰렛 영역
            Expanded(
              // [핵심] 일본어 로케일 강제 적용 (에뮬레이터 언어 무관)
              child: Localizations.override(
                context: context,
                locale: const Locale('ja'),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date, // 날짜만
                  initialDateTime: initial,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime(2100),
                  dateOrder: DatePickerDateOrder.ymd, // [핵심] 연-월-일 순서
                  use24hFormat: true,
                  onDateTimeChanged: (newDate) {
                    setState(() {
                      if (isDeadline) {
                        _deadlineDate = DateTime(newDate.year, newDate.month, newDate.day, _deadlineDate.hour, _deadlineDate.minute);
                      } else {
                        _reminderDate = DateTime(newDate.year, newDate.month, newDate.day, _reminderDate.hour, _reminderDate.minute);
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

  // 시간 선택기 (기존 유지 - 5분 단위)
  void _pickTime(bool isDeadline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime initial = isDeadline ? _deadlineDate : _reminderDate;
    initial = _getNearestFiveMinuteInterval(initial); // 5분 보정

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
                    child: const Text("完了", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time, // 시간만
                initialDateTime: initial,
                minuteInterval: 5,
                use24hFormat: true,
                onDateTimeChanged: (newTime) {
                  setState(() {
                    if (isDeadline) {
                      _deadlineDate = DateTime(_deadlineDate.year, _deadlineDate.month, _deadlineDate.day, newTime.hour, newTime.minute);
                    } else {
                      _reminderDate = DateTime(_reminderDate.year, _reminderDate.month, _reminderDate.day, newTime.hour, newTime.minute);
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
    // ... (기존 build 메서드와 동일) ...
    // 아래 내용은 변경된 부분이 없으므로 위에서 작성한 _pickDate만 교체되면 됩니다.
    // 편의를 위해 UI 부분 코드도 다시 적어드립니다.

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
            decoration: const InputDecoration(hintText: "タスク名", border: InputBorder.none),
          ),
          const Divider(),
          const SizedBox(height: 10),

          const Text(
            "締め切り (Deadline)",
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => _pickDate(true), // 수정된 함수 호출
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 20),
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
                  onTap: () => _pickTime(true),
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
                        const Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
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
                "通知設定 (Notification)",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Switch.adaptive(value: _isReminderEnabled, onChanged: (val) => setState(() => _isReminderEnabled = val)),
            ],
          ),

          if (_isReminderEnabled) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _pickDate(false), // 수정된 함수 호출
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange.withOpacity(0.05),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy/MM/dd').format(_reminderDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange),
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
                    onTap: () => _pickTime(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange.withOpacity(0.05),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(_reminderDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange),
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
              child: const Text("保存する", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
