import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:the_we_system/common/components/processing_card.dart';
import 'package:the_we_system/common/components/side_bar.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';
import 'package:the_we_system/features/approval/domain/entities/approval_document.dart';
import 'package:the_we_system/features/approval/presentation/controllers/approval_providers.dart';
import 'package:the_we_system/features/approval/presentation/widgets/approval_empty_state.dart';

class ApprovalHomePage extends ConsumerStatefulWidget {
  const ApprovalHomePage({super.key});

  @override
  ConsumerState<ApprovalHomePage> createState() => _ApprovalHomePageState();
}

class _ApprovalHomePageState extends ConsumerState<ApprovalHomePage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController waitingScrollController = ScrollController();

  @override
  void dispose() {
    searchController.dispose();
    waitingScrollController.dispose();
    super.dispose();
  }

  void _scrollWaitingDocuments(double delta) {
    if (!waitingScrollController.hasClients) {
      return;
    }

    final target = (waitingScrollController.offset + delta).clamp(
      0.0,
      waitingScrollController.position.maxScrollExtent,
    );

    waitingScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalDashboardControllerProvider);

    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: state.when(
        data: (approvalState) {
          final dashboard = approvalState.dashboard;
          final keyword = approvalState.keyword.trim();
          final waitingDocuments = _filterDocuments(
            dashboard.waitingDocuments,
            keyword,
          );

          return Row(
            children: [
              SideBar(
                frequentForms: dashboard.frequentForms,
                pendingDocument: dashboard.pendingCount,
                receiveDocument: dashboard.receivedCount,
                openPendingDocument: dashboard.referenceCount,
                scheduledDocument: dashboard.scheduledCount,
              ),
              VerticalDivider(
                width: 1,
                color: TheWeColor.black300.withValues(alpha: 0.32),
              ),
              Expanded(
                child: SafeArea(
                  child: RefreshIndicator(
                    color: TheWeColor.blue300,
                    onRefresh: () => ref
                        .read(approvalDashboardControllerProvider.notifier)
                        .refresh(),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: _Header(
                              userName:
                                  approvalState.currentUser?.name ?? '사용자',
                              controller: searchController,
                              onChanged: ref
                                  .read(
                                    approvalDashboardControllerProvider
                                        .notifier,
                                  )
                                  .updateKeyword,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: _PortalOverview(state: approvalState),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                          sliver: SliverToBoxAdapter(
                            child: _ProcessingSection(
                              title: '결재 대기 문서',
                              documents: waitingDocuments,
                              controller: waitingScrollController,
                              onScrollLeft: () => _scrollWaitingDocuments(-300),
                              onScrollRight: () => _scrollWaitingDocuments(300),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                          sliver: SliverToBoxAdapter(
                            child: _DraftProgressSection(
                              documents: dashboard.processingDocuments
                                  .take(10)
                                  .toList(),
                              totalCount: dashboard.processingDocuments.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) => _LoadFailed(
          onRetry: () =>
              ref.read(approvalDashboardControllerProvider.notifier).refresh(),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: TheWeColor.blue300)),
      ),
    );
  }

  List<ApprovalDocument> _filterDocuments(
    List<ApprovalDocument> documents,
    String keyword,
  ) {
    if (keyword.isEmpty) {
      return documents;
    }

    return documents.where((document) {
      return document.title.contains(keyword) ||
          document.drafter.contains(keyword) ||
          document.form.contains(keyword) ||
          document.department.contains(keyword);
    }).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.controller,
    required this.onChanged,
  });

  final String userName;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;

        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          children: [
            SizedBox(
              width: narrow ? constraints.maxWidth : 360,
              child: Row(
                children: [
                  Text('홈', style: TheWeTextStyle.pageTitle),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TheWeColor.blue100.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$userName님',
                      style: TheWeTextStyle.caption.copyWith(
                        color: TheWeColor.blue300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: narrow ? constraints.maxWidth : 360,
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: controller,
                      height: 42,
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        hintText: '문서명, 기안자, 양식 검색',
                        prefixIcon: Icon(
                          Icons.search,
                          color: TheWeColor.black500,
                          size: 18,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconAction(
                    icon: Icons.settings_outlined,
                    message: '설정',
                    onPressed: () => context.goNamed(AppRouteName.settings),
                  ),
                  const SizedBox(width: 6),
                  _IconAction(
                    icon: Icons.help_outline,
                    message: '도움말',
                    onPressed: () => context.goNamed(AppRouteName.help),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

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
                    SizedBox(
                      height: 292,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.dashboard.processingDocuments.length
                            .clamp(0, 4),
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final document =
                              state.dashboard.processingDocuments[index];
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _PortalCalendarPanel extends StatefulWidget {
  const _PortalCalendarPanel();

  @override
  State<_PortalCalendarPanel> createState() => _PortalCalendarPanelState();
}

class _PortalCalendarPanelState extends State<_PortalCalendarPanel> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late final Map<DateTime, List<_PortalCalendarEvent>> _events;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateUtils.dateOnly(now);
    _selectedDay = DateUtils.dateOnly(now);
    _events = _seedEvents(now);
  }

  Map<DateTime, List<_PortalCalendarEvent>> _seedEvents(DateTime baseDate) {
    final year = baseDate.year;
    final month = baseDate.month;

    return {
      DateTime(year, month, 3): const [
        _PortalCalendarEvent(
          title: '세무 마감',
          time: '09:00',
          place: '회계팀',
          colorKey: 'blue',
        ),
      ],
      DateTime(year, month, 5): const [
        _PortalCalendarEvent(
          title: '주간 보고',
          time: '10:00',
          place: '회의실 A',
          colorKey: 'orange',
        ),
      ],
      DateTime(year, month, 8): const [
        _PortalCalendarEvent(
          title: '근태 점검',
          time: '14:00',
          place: '인사팀',
          colorKey: 'pink',
        ),
      ],
      DateTime(year, month, 14): const [
        _PortalCalendarEvent(
          title: '부서 회의',
          time: '09:30',
          place: '회의실 B',
          colorKey: 'blue',
        ),
        _PortalCalendarEvent(
          title: '문서 검수',
          time: '16:00',
          place: '전자결재',
          colorKey: 'orange',
        ),
      ],
      DateTime(year, month, 27): const [
        _PortalCalendarEvent(
          title: '교육 일정',
          time: '13:00',
          place: '교육장',
          colorKey: 'pink',
        ),
      ],
    };
  }

  List<_PortalCalendarEvent> _eventsForDay(DateTime day) {
    return _events[DateUtils.dateOnly(day)] ?? const [];
  }

  void _moveMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      _selectedDay = DateUtils.dateOnly(_focusedDay);
    });
  }

  Future<void> _openAddEventDialog(DateTime day) async {
    final event = await showDialog<_PortalCalendarEvent>(
      context: context,
      builder: (context) => _CalendarEventDialog(date: day),
    );

    if (event == null) {
      return;
    }

    setState(() {
      final key = DateUtils.dateOnly(day);
      _events.putIfAbsent(key, () => []).add(event);
      _selectedDay = key;
      _focusedDay = key;
    });
  }

  Future<void> _openEventDetail(
    DateTime day,
    _PortalCalendarEvent event,
  ) async {
    final action = await showDialog<_CalendarEventAction>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TheWeColor.white,
        surfaceTintColor: TheWeColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(event.title, style: TheWeTextStyle.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalendarDetailLine(label: '날짜', value: _formatKoreanDate(day)),
            _CalendarDetailLine(label: '시간', value: event.time),
            _CalendarDetailLine(label: '장소', value: event.place),
            _CalendarColorDetailLine(color: event.color),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_CalendarEventAction.delete),
            child: Text(
              '삭제',
              style: TheWeTextStyle.body.copyWith(color: TheWeColor.pink),
            ),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pop(_CalendarEventAction.edit),
            child: const Text('수정'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
            child: const Text('닫기'),
          ),
        ],
      ),
    );

    if (action == _CalendarEventAction.delete) {
      setState(() {
        final key = DateUtils.dateOnly(day);
        _events[key]?.remove(event);
      });
      return;
    }

    if (action != _CalendarEventAction.edit) {
      return;
    }

    final edited = await showDialog<_PortalCalendarEvent>(
      context: context,
      builder: (context) =>
          _CalendarEventDialog(date: day, initialEvent: event),
    );

    if (edited == null) {
      return;
    }

    setState(() {
      final key = DateUtils.dateOnly(day);
      final dayEvents = _events[key];
      if (dayEvents == null) {
        return;
      }
      final index = dayEvents.indexOf(event);
      if (index == -1) {
        return;
      }
      dayEvents[index] = edited;
    });
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final rowHeight = compact ? 64.0 : 88.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('캘린더', style: TheWeTextStyle.title),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_focusedDay.year}년 ${_focusedDay.month}월',
                    style: TheWeTextStyle.title.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _CalendarNavButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => _moveMonth(-1),
                ),
                const SizedBox(width: 8),
                _CalendarNavButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () => _moveMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: labels
                  .map(
                    (label) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TheWeTextStyle.caption.copyWith(
                            color: label == '일'
                                ? TheWeColor.pink
                                : TheWeColor.black500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            TableCalendar<_PortalCalendarEvent>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: _focusedDay,
              rowHeight: rowHeight,
              availableGestures: AvailableGestures.none,
              headerVisible: false,
              daysOfWeekVisible: false,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: _eventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: true,
                markerSize: 0,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                final day = DateUtils.dateOnly(selectedDay);
                setState(() {
                  _selectedDay = day;
                  _focusedDay = focusedDay;
                });
                _openAddEventDialog(day);
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              calendarBuilders: CalendarBuilders<_PortalCalendarEvent>(
                defaultBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                todayBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: true,
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                selectedBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: true,
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                outsideBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: false,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                disabledBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
                holidayBuilder: (context, day, focusedDay) => _CalendarDayCard(
                  date: day,
                  isCurrentMonth: day.month == focusedDay.month,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: isSameDay(day, _selectedDay),
                  events: _eventsForDay(day),
                  onEventTap: (event) => _openEventDetail(day, event),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '날짜를 클릭하면 일정을 추가할 수 있습니다.',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PortalNoticePanel extends StatelessWidget {
  const _PortalNoticePanel();

  static const _items = [
    _PortalNotice(
      category: '세무정보',
      title: '2026년 7월 세무일정 안내',
      date: '2026-06-26',
      body: '7월 원천세 신고, 부가세 예정 신고, 지급명세서 제출 일정을 확인해 주세요.',
    ),
    _PortalNotice(
      category: '시스템 안내',
      title: '[외부기관 연동센터] 변경사항 공지',
      date: '2026-06-26',
      body: '외부기관 연동센터 인증 방식이 갱신되었습니다. 전자결재 첨부 연동은 정상 이용 가능합니다.',
    ),
    _PortalNotice(
      category: '시스템 안내',
      title: '[외부기관 연동센터] 점검 일정',
      date: '2026-06-23',
      body: '정기 점검 시간에는 일부 문서 조회와 파일 첨부가 지연될 수 있습니다.',
    ),
    _PortalNotice(
      category: '시스템 안내',
      title: '[외부기관 연동센터] 작업 완료',
      date: '2026-06-23',
      body: '연동센터 작업이 완료되어 모든 전자결재 및 근태 메뉴를 정상 이용할 수 있습니다.',
    ),
  ];

  void _showDetail(BuildContext context, _PortalNotice notice) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notice.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${notice.category} · ${notice.date}',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(height: 16),
            Text(notice.body, style: TheWeTextStyle.body),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('공지사항', style: TheWeTextStyle.title),
            const SizedBox(height: 18),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () => _showDetail(context, item),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.category}  ${item.title}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TheWeTextStyle.body,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.date,
                                style: TheWeTextStyle.caption.copyWith(
                                  color: TheWeColor.black500,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.category}  ${item.title}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TheWeTextStyle.body,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.date,
                                style: TheWeTextStyle.caption.copyWith(
                                  color: TheWeColor.black500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PortalNotice {
  const _PortalNotice({
    required this.category,
    required this.title,
    required this.date,
    required this.body,
  });

  final String category;
  final String title;
  final String date;
  final String body;
}

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onPressed});

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

class _PortalCalendarEvent {
  const _PortalCalendarEvent({
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

enum _CalendarEventAction { edit, delete }

class _CalendarDayCard extends StatelessWidget {
  const _CalendarDayCard({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.events,
    required this.onEventTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<_PortalCalendarEvent> events;
  final ValueChanged<_PortalCalendarEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tooSmallForDetails =
            constraints.maxWidth < 34 || constraints.maxHeight < 42;
        final veryCompact = constraints.maxWidth < 76;
        final textColor = isCurrentMonth
            ? TheWeColor.black900
            : TheWeColor.black500.withValues(alpha: 0.6);
        final dayText = Text(
          '${date.day}',
          style: TheWeTextStyle.caption.copyWith(
            color: isSelected ? TheWeColor.white : textColor,
            fontWeight: FontWeight.w700,
            fontSize: constraints.maxWidth < 34 ? 10 : null,
          ),
        );

        if (tooSmallForDetails) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? TheWeColor.black900
                  : isToday
                  ? const Color(0xFFE7ECFF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: dayText,
          );
        }

        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: TheWeColor.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? TheWeColor.black900
                  : TheWeColor.black300.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TheWeColor.black900
                        : isToday
                        ? const Color(0xFFE7ECFF)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: dayText,
                ),
              ),
              const SizedBox(height: 6),
              if (events.isEmpty)
                const Spacer()
              else if (veryCompact)
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: events
                      .take(3)
                      .map(
                        (event) => Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: event.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: events
                        .take(2)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: InkWell(
                              onTap: () => onEventTap(event),
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: event.color,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TheWeTextStyle.caption.copyWith(
                                        fontSize: 10,
                                        color: TheWeColor.black900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarEventDialog extends StatefulWidget {
  const _CalendarEventDialog({required this.date, this.initialEvent});

  final DateTime date;
  final _PortalCalendarEvent? initialEvent;

  @override
  State<_CalendarEventDialog> createState() => _CalendarEventDialogState();
}

class _CalendarEventDialogState extends State<_CalendarEventDialog> {
  final titleController = TextEditingController();
  final placeController = TextEditingController();
  String colorKey = 'blue';
  int hour = 9;
  int minute = 0;

  @override
  void initState() {
    super.initState();
    final initialEvent = widget.initialEvent;
    if (initialEvent == null) {
      return;
    }

    titleController.text = initialEvent.title;
    placeController.text = initialEvent.place == '장소 미정'
        ? ''
        : initialEvent.place;
    colorKey = initialEvent.colorKey;
    final parts = initialEvent.time.split(':');
    if (parts.length == 2) {
      hour = int.tryParse(parts.first) ?? 9;
      minute = int.tryParse(parts.last) ?? 0;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TheWeColor.white,
      surfaceTintColor: TheWeColor.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        '${_formatKoreanDate(widget.date)} 일정 ${widget.initialEvent == null ? '추가' : '수정'}',
        style: TheWeTextStyle.title,
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalendarTextField(label: '일정 이름', controller: titleController),
            const SizedBox(height: 12),
            Text('시간', style: TheWeTextStyle.body),
            const SizedBox(height: 8),
            _CalendarTimeSelector(
              hour: hour,
              minute: minute,
              onChanged: (nextHour, nextMinute) {
                setState(() {
                  hour = nextHour;
                  minute = nextMinute;
                });
              },
            ),
            const SizedBox(height: 12),
            _CalendarTextField(label: '장소', controller: placeController),
            const SizedBox(height: 12),
            Text('색상', style: TheWeTextStyle.body),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: ['blue', 'orange', 'pink']
                  .map(
                    (item) => _CalendarColorChoice(
                      color: _calendarColor(item),
                      selected: colorKey == item,
                      onTap: () => setState(() => colorKey = item),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final title = titleController.text.trim();
            if (title.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _PortalCalendarEvent(
                title: title,
                time:
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                place: placeController.text.trim().isEmpty
                    ? '장소 미정'
                    : placeController.text.trim(),
                colorKey: colorKey,
              ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: TheWeColor.blue300),
          child: Text(widget.initialEvent == null ? '추가' : '수정'),
        ),
      ],
    );
  }
}

class _CalendarTimeSelector extends StatelessWidget {
  const _CalendarTimeSelector({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TimeWheelColumn(
            value: hour,
            max: 23,
            onChanged: (value) => onChanged(value, minute),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              ':',
              style: TheWeTextStyle.pageTitle.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          _TimeWheelColumn(
            value: minute,
            max: 59,
            onChanged: (value) => onChanged(hour, value),
          ),
        ],
      ),
    );
  }
}

class _TimeWheelColumn extends StatelessWidget {
  const _TimeWheelColumn({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  int _normalized(int next) {
    if (next < 0) {
      return max;
    }
    if (next > max) {
      return 0;
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final previous = _normalized(value - 1);
    final next = _normalized(value + 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => onChanged(previous),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(
              previous.toString().padLeft(2, '0'),
              style: TheWeTextStyle.title.copyWith(
                color: TheWeColor.black500.withValues(alpha: 0.52),
              ),
            ),
          ),
        ),
        Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: TheWeColor.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: TheWeTextStyle.pageTitle.copyWith(
              color: TheWeColor.black900,
            ),
          ),
        ),
        InkWell(
          onTap: () => onChanged(next),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(
              next.toString().padLeft(2, '0'),
              style: TheWeTextStyle.title.copyWith(
                color: TheWeColor.black500.withValues(alpha: 0.52),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarColorChoice extends StatelessWidget {
  const _CalendarColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color : TheWeColor.black300.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _CalendarTextField extends StatelessWidget {
  const _CalendarTextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TheWeTextStyle.body),
        const SizedBox(height: 8),
        CustomTextFormField(controller: controller),
      ],
    );
  }
}

class _CalendarDetailLine extends StatelessWidget {
  const _CalendarDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: TheWeTextStyle.body)),
        ],
      ),
    );
  }
}

class _CalendarColorDetailLine extends StatelessWidget {
  const _CalendarColorDetailLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '색상',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

Color _calendarColor(String colorKey) {
  return switch (colorKey) {
    'blue' => TheWeColor.blue300,
    'orange' => const Color(0xFFF59E0B),
    'pink' => TheWeColor.pink,
    _ => TheWeColor.blue300,
  };
}

String _formatKoreanDate(DateTime date) {
  return '${date.year}년 ${date.month}월 ${date.day}일';
}

class _HeadcountLegend extends StatelessWidget {
  const _HeadcountLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TheWeTextStyle.caption.copyWith(
            color: TheWeColor.black900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PortalTrendChart extends StatelessWidget {
  const _PortalTrendChart({
    required this.totalCount,
    required this.joinerCount,
  });

  final int totalCount;
  final int joinerCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: CustomPaint(
            painter: _TrendPainter(
              totalCount: totalCount,
              joinerCount: joinerCount,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '기준 인원',
              style: TheWeTextStyle.caption.copyWith(
                color: TheWeColor.black500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$totalCount명',
              style: TheWeTextStyle.subtitle.copyWith(color: TheWeColor.green),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.totalCount, required this.joinerCount});

  final int totalCount;
  final int joinerCount;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    final axisStyle = TextStyle(
      color: TheWeColor.black500,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    const leftPadding = 26.0;
    const bottomPadding = 26.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    for (var i = 0; i <= 5; i++) {
      final y = chartHeight * i / 5;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);
      textPainter
        ..text = TextSpan(text: '${10 - i * 2}', style: axisStyle)
        ..layout(minWidth: 20, maxWidth: 20)
        ..paint(canvas, Offset(0, y - 7));
    }

    final months = ['1월', '3월', '5월', '7월'];
    for (var i = 0; i < months.length; i++) {
      final x = leftPadding + chartWidth * i / (months.length - 1);
      textPainter
        ..text = TextSpan(text: months[i], style: axisStyle)
        ..layout(minWidth: 34, maxWidth: 34)
        ..paint(canvas, Offset(x - 17, chartHeight + 8));
    }

    Path linePath(List<double> values) {
      final maxValue = math.max(10, totalCount + 1).toDouble();
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = leftPadding + chartWidth * i / (values.length - 1);
        final y = chartHeight - (values[i] / maxValue * (chartHeight - 10));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    final totalValues = [
      math.max(0, totalCount - 1).toDouble(),
      totalCount.toDouble(),
      math.max(0, totalCount - joinerCount + 1).toDouble(),
      totalCount.toDouble(),
    ];
    final joinValues = [
      0.0,
      math.max(1, joinerCount - 1).toDouble(),
      joinerCount.toDouble(),
      math.max(0, joinerCount - 1).toDouble(),
    ];
    final leaveValues = [0.0, 0.0, 1.0, 0.0];

    void drawLine(Path path, Color color, {double width = 3}) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawLine(linePath(totalValues), TheWeColor.green);
    drawLine(linePath(joinValues), TheWeColor.blue300, width: 2.5);
    drawLine(linePath(leaveValues), TheWeColor.pink, width: 2.5);

    canvas.drawLine(
      Offset(leftPadding, size.height - 4),
      Offset(size.width, size.height - 4),
      Paint()
        ..color = const Color(0xFFE5ECFF)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return totalCount != oldDelegate.totalCount ||
        joinerCount != oldDelegate.joinerCount;
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.message,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: TheWeColor.black900,
      ),
    );
  }
}

class _ProcessingSection extends StatelessWidget {
  const _ProcessingSection({
    required this.title,
    required this.documents,
    required this.controller,
    required this.onScrollLeft,
    required this.onScrollRight,
  });

  final String title;
  final List<ApprovalDocument> documents;
  final ScrollController controller;
  final VoidCallback onScrollLeft;
  final VoidCallback onScrollRight;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, actionLabel: '0건'),
          const SizedBox(height: 12),
          const ApprovalEmptyState(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, actionLabel: '${documents.length}건'),
        const SizedBox(height: 12),
        SizedBox(
          height: 296,
          child: ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemCount: documents.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final document = documents[index];
              return ProcessingCard(
                title: document.title,
                drafter: document.drafter,
                date: document.draftedAt,
                form: document.form,
                status: document.status,
                progress: document.progress,
                onTap: () => context.goNamed(
                  AppRouteName.detail,
                  pathParameters: {'id': document.id},
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundMoveButton(
              icon: Icons.chevron_left,
              tooltip: '이전 결재 대기 문서',
              onPressed: onScrollLeft,
            ),
            const SizedBox(width: 14),
            _RoundMoveButton(
              icon: Icons.chevron_right,
              tooltip: '다음 결재 대기 문서',
              onPressed: onScrollRight,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundMoveButton extends StatelessWidget {
  const _RoundMoveButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: TheWeColor.black900,
        style: IconButton.styleFrom(
          fixedSize: const Size(38, 38),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _DraftProgressSection extends StatelessWidget {
  const _DraftProgressSection({
    required this.documents,
    required this.totalCount,
  });

  final List<ApprovalDocument> documents;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('기안 진행 문서', style: TheWeTextStyle.title),
                const SizedBox(width: 6),
                Tooltip(
                  message: '내가 기안했고 아직 완료되지 않은 문서입니다.',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: TheWeColor.black300,
                  ),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: () => context.goNamed(
                AppRouteName.box,
                pathParameters: {'kind': 'sent'},
              ),
              child: Text('더보기 ($totalCount)', style: TheWeTextStyle.subtitle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tableWidth = constraints.maxWidth < 820
                ? 820.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: TheWeColor.white,
                    border: Border.all(
                      color: TheWeColor.black300.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const _DraftProgressHeader(),
                      ...documents.map(
                        (document) => _DraftProgressRow(document: document),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DraftProgressHeader extends StatelessWidget {
  const _DraftProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: TheWeColor.black300.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: const [
          _DraftProgressCell('기안일', flex: 2, header: true),
          _DraftProgressCell('결재양식', flex: 3, header: true),
          _DraftProgressCell('긴급', flex: 1, header: true),
          _DraftProgressCell('제목', flex: 6, header: true),
          _DraftProgressCell('첨부', flex: 1, header: true),
          _DraftProgressCell('결재상태', flex: 2, header: true),
        ],
      ),
    );
  }
}

class _DraftProgressRow extends StatelessWidget {
  const _DraftProgressRow({required this.document});

  final ApprovalDocument document;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.goNamed(
        AppRouteName.detail,
        pathParameters: {'id': document.id},
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: TheWeColor.black300.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            _DraftProgressCell(document.draftedAt, flex: 2),
            _DraftProgressCell(document.form, flex: 3),
            _DraftProgressCell(document.urgent ? '긴급' : '-', flex: 1),
            Expanded(
              flex: 6,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TheWeTextStyle.body,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new, size: 15, color: TheWeColor.black300),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Icon(
                Icons.attach_file,
                size: 16,
                color: document.linkedDocuments.isEmpty
                    ? TheWeColor.black300.withValues(alpha: 0.55)
                    : TheWeColor.black500,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TheWeColor.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    document.status,
                    style: TheWeTextStyle.caption.copyWith(
                      color: TheWeColor.green,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftProgressCell extends StatelessWidget {
  const _DraftProgressCell(
    this.text, {
    required this.flex,
    this.header = false,
  });

  final String text;
  final int flex;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (header ? TheWeTextStyle.caption : TheWeTextStyle.body).copyWith(
          color: header ? TheWeColor.black500 : TheWeColor.black900,
          fontWeight: header ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: TheWeTextStyle.title),
        const Spacer(),
        Text(
          actionLabel,
          style: TheWeTextStyle.caption.copyWith(color: TheWeColor.black500),
        ),
      ],
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, color: TheWeColor.black500, size: 32),
          const SizedBox(height: 12),
          Text('결재 정보를 불러오지 못했습니다.', style: TheWeTextStyle.subtitle),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
