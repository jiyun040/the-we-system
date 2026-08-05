part of 'approval_home_page.dart';

class _PortalOverview extends StatelessWidget {
  const _PortalOverview({required this.state});

  final ApprovalDashboardState state;

  @override
  Widget build(BuildContext context) {
    final accountCount = state.accounts.length;
    final joinerCount = state.accounts
        .where((item) => item.id.toLowerCase() != 'admin')
        .length
        .clamp(0, 3);

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
                  _HeadcountLegend(label: '총 인원', color: TheWeColor.green),
                  _HeadcountLegend(label: '입사자', color: TheWeColor.blue300),
                  _HeadcountLegend(label: '퇴사자', color: TheWeColor.pink),
                ],
              ),
              const SizedBox(height: 18),
              _PortalTrendChart(
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
                  return const _PortalSurface(child: _PortalCalendarPanel());
                }
                final compact = innerConstraints.maxWidth < 720;
                if (compact) {
                  return Column(
                    children: [
                      const _PortalSurface(child: _PortalCalendarPanel()),
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
                      child: _PortalSurface(child: _PortalCalendarPanel()),
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
            const _PortalSurface(child: _PortalNoticePanel()),
            if (state.isAppEnabled(PortalAppId.approval) &&
                processingDocuments.isNotEmpty) ...[
              const SizedBox(height: 18),
              _PortalSurface(
                child: _DraftProgressSection(
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
