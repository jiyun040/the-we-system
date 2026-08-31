import 'package:flutter/material.dart';
import 'package:the_we_system/common/constants/color.dart';
import 'package:the_we_system/common/constants/text_style.dart';
import 'package:the_we_system/core/network/api_exception.dart';

class ApprovalErrorState extends StatelessWidget {
  const ApprovalErrorState({
    super.key,
    required this.error,
    this.title = '정보를 불러오지 못했습니다.',
    this.fallbackMessage = '잠시 후 다시 시도해 주세요.',
    this.onRetry,
  });

  final Object error;
  final String title;
  final String fallbackMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = userFacingErrorMessage(error, fallback: fallbackMessage);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TheWeColor.dangerSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TheWeColor.danger.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: TheWeColor.danger,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TheWeTextStyle.subtitle,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TheWeTextStyle.body.copyWith(
                  color: TheWeColor.black500,
                  height: 1.5,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('다시 시도'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
