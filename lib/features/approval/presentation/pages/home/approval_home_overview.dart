import 'approval_home_dependencies.dart';
import 'approval_home_calendar_panel.dart';
import 'approval_home_notice.dart';
import 'approval_home_processing.dart';
import 'approval_home_trend.dart';

class ApprovalHomeOverview extends StatelessWidget {
  const ApprovalHomeOverview({super.key, required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context) {
    final accountCount = state.accounts.length;
    final now = DateTime.now();
    final joinerCount = state.accounts.where((item) {
      final hiredAt = DateTime.tryParse(item.hireDate);
      return hiredAt != null &&
          hiredAt.year == now.year &&
          hiredAt.month == now.month;
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1100;
        final headcountChild = _PortalSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('인력 현황', style: TheWeTextStyle.title),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  ApprovalHeadcountLegend(
                    label: '총 인원',
                    color: TheWeColor.green,
                  ),
                  ApprovalHeadcountLegend(
                    label: '입사자',
                    color: TheWeColor.blue300,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ApprovalHomeTrendChart(
                totalCount: accountCount,
                joinerCount: joinerCount,
              ),
            ],
          ),
        );
        final leftChild = Column(
          children: [
            LayoutBuilder(
              builder: (context, innerConstraints) {
                if (!state.isAdminMode) {
                  return const _PortalSurface(
                    child: ApprovalHomeCalendarPanel(),
                  );
                }
                final compact = innerConstraints.maxWidth < 720;
                if (compact) {
                  return Column(
                    children: [
                      const _PortalSurface(child: ApprovalHomeCalendarPanel()),
                      const SizedBox(height: 24),
                      headcountChild,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 5,
                      child: _PortalSurface(child: ApprovalHomeCalendarPanel()),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 6, child: headcountChild),
                  ],
                );
              },
            ),
          ],
        );
        final processingDocuments = state.dashboard.processingDocuments;
        final rightChild = Column(
          children: [
            const _PortalSurface(child: ApprovalHomeNoticePanel()),
            if (state.isAppEnabled(PortalAppId.approval) &&
                processingDocuments.isNotEmpty) ...[
              const SizedBox(height: 18),
              _PortalSurface(
                child: ApprovalDraftProgressSection(
                  documents: processingDocuments.take(5).toList(),
                  totalCount: processingDocuments.length,
                ),
              ),
            ],
          ],
        );

        if (stacked) {
          return Column(
            children: [leftChild, const SizedBox(height: 18), rightChild],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: leftChild),
            const SizedBox(width: 18),
            Expanded(flex: 4, child: rightChild),
          ],
        );
      },
    );
  }
}

class _PortalSurface extends StatelessWidget {
  const _PortalSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 520;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 16 : 24),
      child: child,
    );
  }
}
