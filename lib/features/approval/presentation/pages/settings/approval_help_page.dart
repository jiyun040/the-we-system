import 'package:flutter/material.dart';
import 'package:the_we_system/common/components/the_we_back_button.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';

class ApprovalHelpPage extends StatelessWidget {
  const ApprovalHelpPage({super.key});

  static const _items = [
    (
      '결재와 반려는 어떻게 다른가요?',
      '결재는 현재 단계의 승인 처리를 의미합니다. 반려는 기안자에게 문서를 되돌려 수정 후 재상신하도록 요청하는 처리입니다.',
    ),
    (
      '결재 대기 문서는 어디에서 확인하나요?',
      '전자결재 홈의 결재 대기 문서 카드에서 확인합니다. 카드를 선택하면 문서 양식과 결재선을 함께 볼 수 있습니다.',
    ),
    (
      '기안문서함에서 상신취소는 언제 가능한가요?',
      '아직 최종 승인되지 않은 내가 올린 문서는 기안문서함에서 상신취소할 수 있습니다. 취소된 문서는 이력에 남습니다.',
    ),
    (
      '이전 결재를 다시 사용할 수 있나요?',
      '기안문서함 또는 전체 결재 내역에서 재사용을 선택하면 기존 문서 내용을 복사해 수정 후 다시 결재 요청할 수 있습니다.',
    ),
    ('참조자와 열람자는 무엇이 다른가요?', '참조자는 결재 진행 내용을 함께 확인하고, 열람자는 결재가 완료된 문서를 공유받습니다.'),
    (
      '수신자와 공문서 수신자는 어떻게 설정하나요?',
      '결재 작성 화면의 결재 정보에서 수신자와 공문서 수신처 탭을 선택해 내부 수신 부서 또는 외부 공문 수신처를 지정합니다.',
    ),
    (
      '대결자가 승인하면 결재가 완료되나요?',
      '아니요. 부재 설정으로 지정된 대결자가 승인해도 원결재자가 복귀 후 재승인해야 최종 승인으로 처리됩니다.',
    ),
    (
      '문서 수정 이력은 어디서 보나요?',
      '결재 상세 오른쪽 패널의 변경이력 탭에서 결재선 변경과 문서 내용 변경을 확인할 수 있고, 보기 버튼으로 당시 내용을 확인합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TheWeColor.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TheWeBackButton(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '전자결재 도움말',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TheWeTextStyle.pageTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '결재 업무 중 자주 필요한 질문을 정리했습니다.',
                style: TheWeTextStyle.body.copyWith(color: TheWeColor.black500),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];

                    return ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(item.$1, style: TheWeTextStyle.subtitle),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.$2,
                              style: TheWeTextStyle.body.copyWith(height: 1.6),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
