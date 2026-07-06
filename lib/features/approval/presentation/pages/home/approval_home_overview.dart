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
            const SizedBox(height: 18),
            _PortalSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('전자결재 진행현황', style: TheWeTextStyle.title),
                  const SizedBox(height: 18),
                  if (state.dashboard.processingDocuments.isEmpty)
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          '목록이 없습니다.',
                          style: TheWeTextStyle.body.copyWith(
                            color: TheWeColor.black500,
                          ),
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final documents = state.dashboard.processingDocuments;
                        if (constraints.maxWidth < 520) {
                          return Column(
                            children: documents
                                .take(3)
                                .map(
                                  (document) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ApprovalMobileDocumentCard(
                                      document: document,
                                      onTap: () => context.goNamed(
                                        AppRouteName.detail,
                                        pathParameters: {'id': document.id},
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        }

                        return SizedBox(
                          height: 292,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: documents.length.clamp(0, 4),
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final document = documents[index];
                              return ProcessingCard(
                                title: document.title,
                                drafter: document.drafter,
                                date: document.draftedAt,
                                form: document.form,
                                status: document.status,
                                progress: document.progress,
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        );
        const rightChild = _PortalSurface(child: _PortalNoticePanel());

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
