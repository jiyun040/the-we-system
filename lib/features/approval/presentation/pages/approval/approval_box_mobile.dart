part of 'approval_box_page.dart';

class _DocumentMobileList extends StatelessWidget {
  const _DocumentMobileList({
    required this.kind,
    required this.documents,
    required this.canCancelForCurrentUser,
    required this.onCancel,
  });

  final String kind;
  final List<ApprovalDocument> documents;
  final bool Function(ApprovalDocument document) canCancelForCurrentUser;
  final ValueChanged<String> onCancel;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const ApprovalEmptyState();
    }

    return ListView.separated(
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final document = documents[index];
        return ApprovalMobileDocumentCard(
          document: document,
          onTap: () => context.goNamed(
            AppRouteName.detail,
            pathParameters: {'id': document.id},
          ),
          actions: [
            if (kind == 'drafts' && canCancelForCurrentUser(document))
              OutlinedButton(
                onPressed: () => onCancel(document.id),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: TheWeColor.pink),
                ),
                child: Text(
                  '상신취소',
                  style: TheWeTextStyle.section.copyWith(
                    color: TheWeColor.pink,
                  ),
                ),
              ),
            OutlinedButton(
              onPressed: () => context.goNamed(
                AppRouteName.draft,
                queryParameters: {'reuse': document.id},
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: TheWeColor.blue300),
              ),
              child: Text(
                document.status == '작성중' ? '이어쓰기' : '재사용',
                style: TheWeTextStyle.section.copyWith(
                  color: TheWeColor.blue300,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
