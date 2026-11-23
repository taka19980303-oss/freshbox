import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/notification_service.dart';
import 'analytics_screen.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // プライバシーポリシー URL (実際のURLに変更すること)
  static const String _privacyPolicyUrl =
      'https://example.com/freshbox/privacy-policy';

  Future<void> _launchUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リンクを開けませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2B5FA6), Color(0xFF1B3A6B)],
                  ),
                ),
              ),
              title: Text(
                '設定',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            backgroundColor: const Color(0xFF1B3A6B),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── アプリ情報 ──
                  _SectionHeader(title: 'アプリ情報'),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: '🍱',
                        label: 'アプリ名',
                        value: 'FreshBox',
                      ),
                      const Divider(height: 1),
                      _InfoRow(
                        icon: '🔖',
                        label: 'バージョン',
                        value: '1.0.0',
                      ),
                      const Divider(height: 1),
                      _InfoRow(
                        icon: '📱',
                        label: '対応 OS',
                        value: 'iOS 16.0以上 / Android 6.0以上',
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // ── 統計分析 ──
                  _SectionHeader(title: '分析レポート'),
                  _InfoCard(
                    children: [
                      _TileRow(
                        icon: Icons.bar_chart_outlined,
                        title: '冷蔵庫分析レポート',
                        subtitle: '在庫の栄養分布やフードロス削減額を確認',
                        iconColor: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                          );
                        },
                        showArrow: true,
                      ),
                    ],
                  ).animate(delay: kIsWeb ? Duration.zero : 50.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // ── データ管理 ──
                  _SectionHeader(title: 'データ管理'),
                  _InfoCard(
                    children: [
                      _TileRow(
                        icon: Icons.storage_outlined,
                        title: 'データの保存場所',
                        subtitle: 'あなたの端末内のみに保存されます',
                        iconColor: AppColors.primary,
                        onTap: null,
                      ),
                      const Divider(height: 1),
                      _TileRow(
                        icon: Icons.notifications_active_outlined,
                        title: 'プッシュ通知テスト実行',
                        subtitle: '即時期限アラートの通知テストを行います',
                        iconColor: AppColors.primary,
                        onTap: () async {
                          await NotificationService.showInstantNotification(
                            title: '期限アラートテストです 🍱',
                            body: '「豚バラ肉」の期限が2日後に迫っています。今日のレシピをチェックして無駄なく使い切りましょう。',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('テスト通知を送信しました！'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        showArrow: true,
                      ),
                      const Divider(height: 1),
                      _TileRow(
                        icon: Icons.cloud_off_outlined,
                        title: 'クラウド同期',
                        subtitle: '現在は端末内のみ。将来アップデートで対応予定',
                        iconColor: AppColors.textTertiary,
                        onTap: null,
                      ),
                    ],
                  ).animate(delay: kIsWeb ? Duration.zero : 100.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // ── 法的情報 ──
                  _SectionHeader(title: '法的情報'),
                  _InfoCard(
                    children: [
                      _TileRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'プライバシーポリシー',
                        subtitle: 'データの取り扱いについて',
                        iconColor: AppColors.tertiary,
                        onTap: () => _launchUrl(_privacyPolicyUrl, context),
                        showArrow: true,
                      ),
                      const Divider(height: 1),
                      _TileRow(
                        icon: Icons.description_outlined,
                        title: '利用規約',
                        subtitle: '本アプリの利用規約',
                        iconColor: AppColors.tertiary,
                        onTap: () => _launchUrl(_privacyPolicyUrl, context),
                        showArrow: true,
                      ),
                    ],
                  ).animate(delay: kIsWeb ? Duration.zero : 200.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // ── フィードバック ──
                  _SectionHeader(title: 'フィードバック'),
                  _InfoCard(
                    children: [
                      _TileRow(
                        icon: Icons.star_outline,
                        title: 'App Storeでレビュー',
                        subtitle: '平価やコメントをお寄せください',
                        iconColor: const Color(0xFFFFB300),
                        onTap: () {
                          // App StoreのレビューURLを開く
                          // 実際のアプリ ID に変更する
                          _launchUrl('https://apps.apple.com/jp/app/id000000000', context);
                        },
                        showArrow: true,
                      ),
                    ],
                  ).animate(delay: kIsWeb ? Duration.zero : 300.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 40),

                  // ── フッター ──
                  Center(
                    child: Column(
                      children: [
                        const Text('🍱', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          'FreshBox v1.0.0',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u00a9 2026 FreshBox. All rights reserved.',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ).animate(delay: kIsWeb ? Duration.zero : 400.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── コンポーネント ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool showArrow;

  const _TileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
