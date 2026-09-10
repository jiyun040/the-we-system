import 'approval_box_dependencies.dart';

class ApprovalDocumentMobileList extends StatelessWidget {
  const ApprovalDocumentMobileList({
    super.key,
    required this.kind,
    required this.documents,
    required this.canCancelForCurrentUser,
    required this.onCancel,
    required this.onDelete,
  });

  final String kind;
  final List<ApprovalDocument> documents;
  final bool Function(ApprovalDocument document) canCancelForCurrentUser;
  final ValueChanged<String> onCancel;
  final ValueChanged<ApprovalDocument> onDelete;

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
          onTap: () => context.pushNamed(
            AppRouteName.detail,
            pathParameters: {'id': document.id},
          ),
          actions: [
            if (kind == 'temporary')
              OutlinedButton(
                key: ValueKey('delete-draft-${document.id}'),
                onPressed: () => onDelete(document),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TheWeColor.danger,
                  side: const BorderSide(color: TheWeColor.danger),
                ),
                child: const Text('삭제'),
              ),
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
              onPressed: () => context.pushNamed(
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
