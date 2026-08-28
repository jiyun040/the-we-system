import 'approval_home_dependencies.dart';

class ApprovalCalendarNavButton extends StatelessWidget {
  const ApprovalCalendarNavButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAF7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF3FAE6A)),
      ),
    );
  }
}

class ApprovalCalendarEvent {
  const ApprovalCalendarEvent({
    required this.title,
    required this.time,
    required this.place,
    required this.colorKey,
  });

  final String title;
  final String time;
  final String place;
  final String colorKey;

  String get colorLabel {
    return switch (colorKey) {
      'blue' => 'blue',
      'orange' => 'orange',
      'pink' => 'pink',
      _ => 'blue',
    };
  }

  Color get color {
    return switch (colorKey) {
      'blue' => TheWeColor.blue300,
      'orange' => const Color(0xFFF59E0B),
      'pink' => TheWeColor.pink,
      _ => TheWeColor.blue300,
    };
  }
}

enum ApprovalCalendarEventAction { edit, delete }
