import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/trainer_application_provider.dart';
import '../widgets/trainer_location_picker_widget.dart';

class TrainerApplicationFormScreen extends ConsumerStatefulWidget {
  const TrainerApplicationFormScreen({super.key});

  @override
  ConsumerState<TrainerApplicationFormScreen> createState() =>
      _TrainerApplicationFormScreenState();
}

class _TrainerApplicationFormScreenState
    extends ConsumerState<TrainerApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _motivationController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  LatLng? _pickedLocation;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _backgroundController.dispose();
    _motivationController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(trainerApplicationRepositoryProvider).submitApplication(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _emptyToNull(_phoneController.text),
            city: _emptyToNull(_cityController.text),
            professionalBackground: _backgroundController.text.trim(),
            motivation: _emptyToNull(_motivationController.text),
            desiredDisplayName: _emptyToNull(_displayNameController.text),
            desiredBio: _emptyToNull(_bioController.text),
            lat: _pickedLocation?.latitude,
            lng: _pickedLocation?.longitude,
          );
      ref.invalidate(ownTrainerApplicationProvider);
      if (mounted) context.go(Routes.trainerApplicationStatus);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerApplicationTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration:
                  InputDecoration(labelText: l10n.trainerApplicationFullName),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.trainerApplicationFieldRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration:
                  InputDecoration(labelText: l10n.trainerApplicationEmail),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? l10n.trainerApplicationEmailInvalid
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.trainerApplicationPhoneOptional,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: l10n.trainerApplicationCityRegion,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _backgroundController,
              decoration: InputDecoration(
                labelText: l10n.trainerApplicationBackground,
              ),
              maxLines: 4,
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.trainerApplicationFieldRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motivationController,
              decoration: InputDecoration(
                labelText: l10n.trainerApplicationMotivationOptional,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.trainerApplicationPublicProfile,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: l10n.trainerApplicationDisplayNameOptional,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: l10n.trainerApplicationBioOptional,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.trainerApplicationLocationOptional,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(l10n.trainerApplicationLocationHint),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TrainerLocationPickerWidget(
                  onLocationPicked: (latLng) =>
                      setState(() => _pickedLocation = latLng),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(l10n.trainerApplicationSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
