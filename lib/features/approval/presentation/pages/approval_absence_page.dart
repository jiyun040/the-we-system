import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_we_system/common/components/text_form_field.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/router/app_router.dart';

class ApprovalAbsencePage extends StatelessWidget {
  ApprovalAbsencePage({super.key});

  final reasonController = TextEditingController(text: '오지 출장');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 820;
            final form = Padding(
              padding: EdgeInsets.all(compact ? 16 : 28),
              child: _AbsenceForm(
                reasonController: reasonController,
                compact: compact,
              ),
            );
            final selector = Container(
              width: compact ? double.infinity : 300,
              height: compact ? 430 : double.infinity,
              color: TheWeColor.black900.withValues(alpha: 0.82),
              padding: const EdgeInsets.all(18),
              child: _SubstituteSelector(),
            );

            if (compact) {
              return SingleChildScrollView(
                child: Column(children: [form, selector]),
              );
            }

            return Row(
              children: [
                Expanded(child: form),
                selector,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AbsenceForm extends StatelessWidget {
  const _AbsenceForm({required this.reasonController, required this.compact});

  final TextEditingController reasonController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? null : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            children: [
              const TheWeBackButton(fallbackRouteName: AppRouteName.settings),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '부재 추가',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TheWeTextStyle.pageTitle,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 24 : 38),
          _FormRow(
            label: '부재 기간',
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                _DateBox(text: '2026-06-28'),
                Text('~'),
                _DateBox(text: '2026-07-03'),
              ],
            ),
          ),
          _FormRow(
            label: '부재 사유',
            child: CustomTextFormField(controller: reasonController),
          ),
          _FormRow(
            label: '대결자',
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('대결자 선택'),
                ),
                Text('이재오 차장', style: TheWeTextStyle.body),
              ],
            ),
          ),
          if (!compact) const Spacer() else const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => context.goNamed(AppRouteName.settings),
                style: FilledButton.styleFrom(
                  backgroundColor: TheWeColor.blue300,
                ),
                child: const Text('확인'),
              ),
              OutlinedButton(
                onPressed: () => context.goNamed(AppRouteName.settings),
                child: Text('취소', style: TheWeTextStyle.body),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        return Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TheWeTextStyle.body),
                    const SizedBox(height: 10),
                    child,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 180,
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

class _SelectorCloseButton extends StatelessWidget {
  const _SelectorCloseButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Icon(Icons.close, color: TheWeColor.white),
      tooltip: '닫기',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: TheWeColor.black300)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month, size: 18, color: TheWeColor.black500),
          const SizedBox(width: 8),
          Text(text, style: TheWeTextStyle.body),
        ],
      ),
    );
  }
}

class _SubstituteSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '대결자 선택',
              style: TheWeTextStyle.subtitle.copyWith(color: TheWeColor.white),
            ),
            const Spacer(),
            const _SelectorCloseButton(),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: searchController,
          decoration: const InputDecoration(hintText: '이름/아이디/부서/직위/직책/...'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            color: TheWeColor.white,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                _OrgNode(text: '다우오피스', group: true),
                _OrgNode(text: '  김윤덕 사장'),
                _OrgNode(text: '  웍스 매니저'),
                _OrgNode(text: '사업본부', group: true),
                _OrgNode(text: '  김경영 상무'),
                _OrgNode(text: '  이재오 차장', selected: true),
                _OrgNode(text: '  관리자 과장'),
                _OrgNode(text: '교육관리팀', group: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(foregroundColor: TheWeColor.white),
            child: const Text('닫기'),
          ),
        ),
      ],
    );
  }
}

class _OrgNode extends StatelessWidget {
  const _OrgNode({
    required this.text,
    this.group = false,
    this.selected = false,
  });

  final String text;
  final bool group;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? TheWeColor.blue100.withValues(alpha: 0.7) : null,
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            group ? Icons.business : Icons.person,
            size: 16,
            color: TheWeColor.black500,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(text.trim(), style: TheWeTextStyle.body)),
        ],
      ),
    );
  }
}
