import 'approval_home_dependencies.dart';

class ApprovalHomeNoticePanel extends StatelessWidget {
  const ApprovalHomeNoticePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('공지사항', style: TheWeTextStyle.title),
        const SizedBox(height: 18),
        Text(
          '서버에 등록된 공지사항이 없습니다.',
          style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
        ),
      ],
    );
  }
}
