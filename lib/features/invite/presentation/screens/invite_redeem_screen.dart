import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/storage/pending_invite_store.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/invite_redeem_result.dart';
import '../invite_messages.dart';
import '../providers/invite_providers.dart';
import '../widgets/invite_confirm_sheet.dart';

/// Manual invite-code entry + confirmation. Used from onboarding and
/// deep links via `/einladung?c=…`.
class InviteRedeemScreen extends ConsumerStatefulWidget {
  const InviteRedeemScreen({
    super.key,
    this.initialCode,
    this.isOnboarding = false,
  });

  final String? initialCode;
  final bool isOnboarding;

  @override
  ConsumerState<InviteRedeemScreen> createState() => _InviteRedeemScreenState();
}

class _InviteRedeemScreenState extends ConsumerState<InviteRedeemScreen> {
  late final TextEditingController _controller;
  String? _inlineError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialCode == null
        ? ''
        : normalizeInviteCodeInput(widget.initialCode!);
    _controller = TextEditingController(text: seed);
    if (seed.isEmpty) {
      unawaited(_loadPendingCode());
    } else {
      unawaited(pendingInviteStore.saveCode(seed));
    }
  }

  Future<void> _loadPendingCode() async {
    final code = await pendingInviteStore.readValidCode();
    if (!mounted || code == null || _controller.text.isNotEmpty) return;
    setState(() {
      _controller.text = code;
      _controller.selection = TextSelection.collapsed(offset: code.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (!mounted) return;
    if (widget.isOnboarding) {
      context.go(Routes.dashboard);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.dashboard);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;
    if (raw == null || raw.isEmpty) return;
    setState(() {
      _controller.text = normalizeInviteCodeInput(raw);
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _inlineError = null;
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final code = normalizeInviteCodeInput(_controller.text);
    if (!isWellFormedInviteCode(code)) {
      setState(() => _inlineError = l10n.inviteErrorUnknownCode);
      return;
    }

    // Persist for the 30-day window; do not block the confirm sheet on I/O
    // (widget tests use a fake async zone that does not drain dart:io).
    unawaited(pendingInviteStore.saveCode(code));

    final confirmed = await showInviteConfirmSheet(context, code: code);
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _inlineError = null;
    });

    try {
      final result =
          await ref.read(inviteActionsProvider.notifier).redeem(code);
      if (!mounted) return;
      final message = inviteRedeemUserMessage(l10n, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      // Every RPC result is terminal for this code (cannot succeed later).
      // Keep the pending code only on decline/skip or transient failures below.
      unawaited(pendingInviteStore.clearCode());
      if (result == InviteRedeemResult.accepted) {
        _finish();
      } else {
        setState(() => _inlineError = message);
      }
    } catch (error) {
      if (!mounted) return;
      // Network / unexpected: keep pending so the user can retry later.
      setState(() => _inlineError = inviteRedeemFailureMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inviteRedeemQuestion),
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text(
              l10n.inviteRedeemQuestion,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              enabled: !_submitting,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: l10n.inviteCodeFieldLabel,
                counterText: '',
                errorText: _inlineError,
              ),
              onChanged: (_) {
                if (_inlineError != null) {
                  setState(() => _inlineError = null);
                }
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _submitting ? null : _paste,
                icon: const Icon(Icons.content_paste_outlined),
                label: Text(l10n.inviteRedeemPaste),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('invite-redeem-submit'),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.inviteConfirmAccept),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('invite-redeem-skip'),
              onPressed: _submitting ? null : _finish,
              child: Text(l10n.inviteRedeemSkip),
            ),
          ],
        ),
      ),
    );
  }
}
