import 'package:corejourney/features/trainer/domain/models/trainer_application.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainerApplication', () {
    test('parses approved application with activation code', () {
      final l10n = lookupAppLocalizations(const Locale('de'));
      final application = TrainerApplication.fromJson({
        'id': 'application-1',
        'user_id': 'user-1',
        'full_name': 'Alex Trainer',
        'email': 'alex@example.com',
        'phone': null,
        'city': 'Berlin',
        'professional_background': 'Physiotherapy',
        'motivation': 'Support clients',
        'desired_display_name': 'Alex',
        'desired_bio': 'Trainer bio',
        'status': 'approved',
        'background_check_required': true,
        'background_check_verified_at': '2026-04-28T10:00:00Z',
        'background_check_verified_by': 'admin-1',
        'reviewed_by': 'admin-1',
        'reviewed_at': '2026-04-28T11:00:00Z',
        'rejection_reason': null,
        'admin_notes': 'ok',
        'activation_code_id': 'code-1',
        'activation_code': 'ABCDEFGH',
        'activation_code_expires_at': '2026-05-12T11:00:00Z',
        'review_channel_id': 'channel-1',
        'created_at': '2026-04-28T09:00:00Z',
        'updated_at': '2026-04-28T11:00:00Z',
      });

      expect(application.status, TrainerApplicationStatus.approved);
      expect(application.hasBackgroundCheck, isTrue);
      expect(application.canApprove, isFalse);
      expect(application.activationCode, 'ABCDEFGH');
      expect(application.statusLabel(l10n), l10n.trainerAppStatusApproved);
      expect(application.statusLabel(l10n), 'Freigegeben');
    });

    test('submitted application can be approved only after background check',
        () {
      final application = TrainerApplication.fromJson({
        'id': 'application-1',
        'user_id': 'user-1',
        'full_name': 'Alex Trainer',
        'email': 'alex@example.com',
        'professional_background': 'Physiotherapy',
        'status': 'submitted',
        'background_check_required': true,
        'created_at': '2026-04-28T09:00:00Z',
        'updated_at': '2026-04-28T09:00:00Z',
      });

      expect(application.isOpen, isTrue);
      expect(application.hasBackgroundCheck, isFalse);
      expect(application.canApprove, isFalse);
    });
  });
}
