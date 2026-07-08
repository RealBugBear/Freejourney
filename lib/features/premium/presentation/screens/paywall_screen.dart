import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/paywall_products.dart';
import '../../domain/purchase_service.dart';
import '../providers/premium_provider.dart';

/// Paywall (Trio B, D4 2026-07-07): Monat / Jahr (hervorgehoben) / Lifetime.
///
/// Bewusst ohne Druck-Mechaniken (keine Countdown-Timer, keine Rabatt-
/// Inszenierung, kein Angst-Framing) und ohne Wirkversprechen — verkauft
/// wird das Programm, nie eine Wirkung. Die ehrliche Dauer-Angabe
/// (10–12 Monate) ist Transparenz und macht das Jahres-Abo rational.
///
/// In T23 führt jeder Kaufversuch auf den [StubPurchaseService]
/// („noch nicht verfügbar“); T25 tauscht den Service gegen RevenueCat.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PaywallProductId _selected = PaywallProductId.yearly;
  bool _busy = false;

  Future<void> _purchase() async {
    setState(() => _busy = true);
    final outcome =
        await ref.read(purchaseServiceProvider).purchase(_selected);
    if (!mounted) return;
    setState(() => _busy = false);
    _handleOutcome(outcome);
  }

  Future<void> _restore() async {
    final outcome = await ref.read(purchaseServiceProvider).restorePurchases();
    if (!mounted) return;
    _handleOutcome(outcome);
  }

  void _handleOutcome(PurchaseOutcome outcome) {
    final l10n = AppLocalizations.of(context);
    switch (outcome) {
      case PurchaseOutcome.success:
        ref.invalidate(entitlementProvider);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.dashboard);
        }
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.notAvailable:
      case PurchaseOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paywallNotAvailable)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paywallTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.paywallSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.paywallDurationNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              for (final product in paywallProducts) ...[
                _ProductCard(
                  product: product,
                  l10n: l10n,
                  selected: _selected == product.id,
                  onTap: () => setState(() => _selected = product.id),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _purchase,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.paywallUnlock),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _restore,
                child: Text(l10n.paywallRestore),
              ),
              Text(
                l10n.paywallCancelNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.l10n,
    required this.selected,
    required this.onTap,
  });

  final PaywallProduct product;
  final AppLocalizations l10n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, period) = switch (product.id) {
      PaywallProductId.monthly => (
          l10n.paywallMonthlyTitle,
          l10n.paywallPerMonth
        ),
      PaywallProductId.yearly => (l10n.paywallYearlyTitle, l10n.paywallPerYear),
      PaywallProductId.lifetime => (l10n.paywallLifetimeTitle, l10n.paywallOnce),
    };

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (product.highlighted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.paywallYearlyBadge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      period,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                product.displayPrice,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
