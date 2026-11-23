import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class SuggestionBanner extends StatelessWidget {
  final String missingIngredient;
  final String recipeName;

  const SuggestionBanner({
    super.key,
    required this.missingIngredient,
    required this.recipeName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBE6),
            Color(0xFFFFF3CD),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'あと1品買い足すと...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF795548),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF5D4037),
              ),
              children: [
                TextSpan(
                  text: missingIngredient,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B6B3A),
                    fontSize: 16,
                  ),
                ),
                const TextSpan(text: ' を追加すると\n'),
                TextSpan(
                  text: '「$recipeName」',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' が完成！'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '近くのスーパーを探す',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}
