import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/mood_provider.dart';

Future<void> showNoteEntrySheet(
  BuildContext context, {
  required String enrollmentId,
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => NoteEntrySheet(
      enrollmentId: enrollmentId,
      onSaved: onSaved,
    ),
  );
}

class NoteEntrySheet extends ConsumerStatefulWidget {
  final String enrollmentId;
  final VoidCallback? onSaved;

  const NoteEntrySheet({
    super.key,
    required this.enrollmentId,
    this.onSaved,
  });

  @override
  ConsumerState<NoteEntrySheet> createState() => _NoteEntrySheetState();
}

class _NoteEntrySheetState extends ConsumerState<NoteEntrySheet> {
  late TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(moodRepositoryProvider);
      await repo.createCheckin(
        enrollmentId: widget.enrollmentId,
        note: text,
        source: 'manual',
      );

      if (!mounted) return;
      widget.onSaved?.call();
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(
          context,
          AppLocalizations.of(context).errorSaveFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEmpty = _noteController.text.trim().isEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.moodWriteNote,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.moodNoteBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.moodNoteHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isEmpty || _saving) ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}
