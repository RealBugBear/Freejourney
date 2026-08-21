import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Explicit confirmation before calling `redeem_invite_code`.
///
/// Shows the normalized [code], the self-check benefit ([inviteWhy]), and the
/// privacy body. Returns `true` when the user accepts, `false` / `null` when
/// they decline or dismiss.
///
/// Content scrolls when text scale or small viewports would otherwise overflow.
Future<bool?> showInviteConfirmSheet(
  BuildContext context, {
  required String code,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.9;
      final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.inviteConfirmTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.inviteCodeFieldLabel,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    code,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.inviteWhy,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.inviteConfirmBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('invite-confirm-accept'),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.inviteConfirmAccept),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('invite-confirm-decline'),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.inviteConfirmDecline),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
