part of 'approval_detail_page.dart';

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return highlighted
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: TheWeColor.blue100.withValues(alpha: 0.75),
              foregroundColor: TheWeColor.black900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
        : TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: TextButton.styleFrom(foregroundColor: TheWeColor.black900),
          );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: TheWeColor.black900,
            indicatorColor: TheWeColor.black900,
            tabs: const [
              Tab(text: '결재선'),
              Tab(text: '문서정보'),
              Tab(text: '변경이력'),
              Tab(text: '열람'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ApprovalLineTab(steps: document.steps),
                _DocumentInfoTab(document: document),
                _HistoryTab(histories: document.histories),
                _ViewerTab(document: document),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalLineTab extends StatelessWidget {
  const _ApprovalLineTab({required this.steps});

  final List<ApprovalStep> steps;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            _HorizontalApprovalStep(step: steps[index]),
            if (index != steps.length - 1)
              SizedBox(
                width: 32,
                height: 138,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: TheWeColor.black300,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HorizontalApprovalStep extends StatelessWidget {
  const _HorizontalApprovalStep({required this.step});

  final ApprovalStep step;

  @override
  Widget build(BuildContext context) {
    final active = step.status == '진행중';
    final completed = step.status == '완료';
    final rejected = step.status == '반려';
    final statusColor = rejected
        ? TheWeColor.danger
        : active
        ? TheWeColor.blue300
        : completed
        ? TheWeColor.blue300
        : TheWeColor.black500;
    return Container(
      width: 150,
      height: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? TheWeColor.blueSurface : TheWeColor.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? TheWeColor.blue300
              : TheWeColor.black300.withValues(alpha: .35),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withValues(alpha: .12),
            child: Icon(Icons.person, size: 19, color: statusColor),
          ),
          const SizedBox(height: 8),
          Text(
            '${step.name} ${step.role}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TheWeTextStyle.body.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            step.department,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TheWeTextStyle.caption,
          ),
          const SizedBox(height: 5),
          Text(
            step.status,
            style: TheWeTextStyle.caption.copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }
}

class _DocumentInfoTab extends StatelessWidget {
  const _DocumentInfoTab({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoLine(label: '문서번호', value: document.documentNo),
        _InfoLine(label: '기안자', value: document.drafter),
        _InfoLine(label: '기안부서', value: document.department),
        _InfoLine(label: '수신자', value: document.receivers.join(', ')),
        _InfoLine(label: '참조자', value: document.references.join(', ')),
        _InfoLine(label: '열람자', value: document.viewers.join(', ')),
        _InfoLine(label: '공문서 수신처', value: document.publicReceivers.join(', ')),
        _InfoLine(label: '긴급문서', value: document.urgent ? '예' : '아니오'),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.histories});

  final List<ApprovalHistory> histories;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('변경 이력', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 8),
        ...histories.map((history) => _HistoryTile(history: history)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.history});

  final ApprovalHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(history.date, style: TheWeTextStyle.caption),
          const SizedBox(height: 4),
          Text(history.user, style: TheWeTextStyle.body),
          const SizedBox(height: 2),
          Text(
            history.description,
            style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
          ),
        ],
      ),
    );
  }
}

class _ViewerTab extends StatelessWidget {
  const _ViewerTab({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('참조자는 결재 중에도 열람 가능', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 8),
        ...document.references.map((name) => _SimplePerson(name: name)),
        const SizedBox(height: 18),
        Text('열람자는 결재 완료 후 열람 가능', style: TheWeTextStyle.subtitle),
        const SizedBox(height: 8),
        ...document.viewers.map((name) => _SimplePerson(name: name)),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TheWeTextStyle.caption),
          const SizedBox(height: 3),
          Text(value.isEmpty ? '-' : value, style: TheWeTextStyle.body),
        ],
      ),
    );
  }
}

class _SimplePerson extends StatelessWidget {
  const _SimplePerson({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline),
      title: Text(name, style: TheWeTextStyle.body),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
