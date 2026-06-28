import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/common/components/the_we_dropdown.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';

class ApprovalSettingsPage extends StatelessWidget {
  const ApprovalSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;

            return Padding(
              padding: EdgeInsets.all(compact ? 16 : 28),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TheWeBackButton(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '결재환경설정',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TheWeTextStyle.pageTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TabBar(
                      isScrollable: true,
                      labelColor: TheWeColor.black900,
                      indicatorColor: TheWeColor.black900,
                      tabs: const [
                        Tab(text: '기본 설정'),
                        Tab(text: '부재/위임 설정'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Expanded(
                      child: TabBarView(
                        children: [_BasicSettings(), _DelegationSettings()],
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: TheWeColor.blue300,
                          ),
                          child: const Text('저장'),
                        ),
                        OutlinedButton(
                          onPressed: () => context.goNamed(AppRouteName.home),
                          child: Text('취소', style: TheWeTextStyle.body),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BasicSettings extends StatelessWidget {
  const _BasicSettings();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SettingRow(
          label: '서명관리',
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(onPressed: () {}, child: Text('서명 올리기', style: TheWeTextStyle.section,)),
              Text(
                '서명은 최대 55x40 pixel이며, 사이즈가 크면 비율에 맞춰 적용됩니다.',
                style: TheWeTextStyle.caption.copyWith(
                  color: TheWeColor.black500,
                ),
              ),
            ],
          ),
        ),
        _SettingRow(
          label: '',
          child: Container(
            width: 116,
            height: 188,
            decoration: BoxDecoration(
              border: Border.all(color: TheWeColor.black500),
            ),
            child: Column(
              children: [
                _StampCell(text: '직위'),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 2),
                      ),
                      child: Text(
                        '승인',
                        style: TheWeTextStyle.caption.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                _StampCell(text: '이름'),
                _StampCell(text: '결재일'),
              ],
            ),
          ),
        ),
        _SettingRow(
          label: '결재 작성 방식',
          child: TheWeDropdown<String>(
            value: '일반 작성',
            width: 180,
            items: const ['일반 작성', '간편 작성'],
            labelBuilder: (value) => value,
            onChanged: (_) {},
          ),
        ),
        _SettingRow(
          label: '첨부 이미지 설정',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _RadioText(
                label: '기본 사이즈로 표시 (썸네일로 표시합니다. 100 x 100 pixel)',
                selected: true,
              ),
              _RadioText(label: '원본 사이즈로 표시 (파일이 여러 개인 경우, 속도저하가 발생할 수 있습니다.)'),
              _RadioText(label: '파일명으로 표시 (파일 이름만 표시합니다.)'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DelegationSettings extends StatelessWidget {
  const _DelegationSettings();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Text('부재/위임 설정', style: TheWeTextStyle.title),
            FilledButton.icon(
              onPressed: () => context.goNamed(AppRouteName.absence),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('부재 추가'),
              style: FilledButton.styleFrom(
                backgroundColor: TheWeColor.blue300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TheWeColor.blue100.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '대결자가 결재를 승인해도 완전 승인으로 처리되지 않습니다. 원결재자가 복귀 후 재승인해야 결재가 완료됩니다.',
            style: TheWeTextStyle.body,
          ),
        ),
        const SizedBox(height: 14),
        _DelegationTile(
          period: '2026-06-28 ~ 2026-07-03',
          reason: '오지 출장',
          substitute: '이재오 차장',
          status: '대결 승인 후 원결재자 확인 필요',
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label.isNotEmpty) ...[
                      Text(label, style: TheWeTextStyle.body),
                      const SizedBox(height: 10),
                    ],
                    child,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Text(label, style: TheWeTextStyle.body),
                    ),
                    Expanded(child: child),
                  ],
                ),
        );
      },
    );
  }
}

class _SettingValue extends StatelessWidget {
  const _SettingValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TheWeTextStyle.caption),
        const SizedBox(height: 4),
        Text(value, style: TheWeTextStyle.body),
      ],
    );
  }
}

class _DelegationTile extends StatelessWidget {
  const _DelegationTile({
    required this.period,
    required this.reason,
    required this.substitute,
    required this.status,
  });

  final String period;
  final String reason;
  final String substitute;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: TheWeColor.black300.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingValue(label: '기간', value: period),
                const SizedBox(height: 12),
                _SettingValue(label: '사유', value: reason),
                const SizedBox(height: 12),
                _SettingValue(label: '대결자', value: substitute),
                const SizedBox(height: 12),
                Text(
                  status,
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.pink,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: Text(period, style: TheWeTextStyle.body)),
              Expanded(child: Text(reason, style: TheWeTextStyle.body)),
              Expanded(child: Text(substitute, style: TheWeTextStyle.body)),
              Expanded(
                child: Text(
                  status,
                  style: TheWeTextStyle.caption.copyWith(
                    color: TheWeColor.pink,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StampCell extends StatelessWidget {
  const _StampCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: TheWeColor.black500)),
      ),
      child: Text(text, style: TheWeTextStyle.body),
    );
  }
}

class _RadioText extends StatelessWidget {
  const _RadioText({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? TheWeColor.blue300 : TheWeColor.black300,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TheWeTextStyle.body)),
        ],
      ),
    );
  }
}
