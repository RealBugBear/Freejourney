import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';

/// Resolves the correct image source for an exercise:
/// prefers the remote Supabase Storage URL when available,
/// falls back to the bundled local asset otherwise, and always terminates in a
/// controlled in-app error surface when neither source can be decoded.
class ExerciseImageWidget extends StatelessWidget {
  final Exercise exercise;
  final bool isDuo;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ExerciseImageWidget({
    super.key,
    required this.exercise,
    this.isDuo = false,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final url = exercise.imageUrlFor(duo: isDuo);
    final localPath = exercise.imagePathFor(duo: isDuo);
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final title = exercise.title(locale);
    final errorLabel = '$title. ${l10n.errorLoadFailedInline}';
    final imageLabel = title;

    return Semantics(
      key: const ValueKey('exercise-image-semantics'),
      container: true,
      image: true,
      label: imageLabel,
      child: _resolvedImage(
        context,
        url: url,
        localPath: localPath,
        errorLabel: errorLabel,
      ),
    );
  }

  Widget _resolvedImage(
    BuildContext context, {
    required String? url,
    required String localPath,
    required String errorLabel,
  }) {
    final localFallback = _localImage(
      context,
      localPath: localPath,
      errorLabel: errorLabel,
    );
    final uri = url == null ? null : Uri.tryParse(url);
    final isSupportedRemoteUri = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;

    if (!isSupportedRemoteUri) return localFallback;

    return CachedNetworkImage(
      imageUrl: uri.toString(),
      fit: fit,
      width: width,
      height: height,
      imageBuilder: (_, imageProvider) => Image(
        image: imageProvider,
        fit: fit,
        width: width,
        height: height,
        excludeFromSemantics: true,
      ),
      placeholder: (_, __) => localFallback,
      errorWidget: (_, __, ___) => localFallback,
    );
  }

  Widget _localImage(
    BuildContext context, {
    required String localPath,
    required String errorLabel,
  }) {
    if (localPath.trim().isEmpty) {
      return _ImageFailureSurface(
        width: width,
        height: height,
        errorLabel: errorLabel,
      );
    }

    return Image.asset(
      localPath,
      fit: fit,
      width: width,
      height: height,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => _ImageFailureSurface(
        width: width,
        height: height,
        errorLabel: errorLabel,
      ),
    );
  }
}

class _ImageFailureSurface extends StatelessWidget {
  const _ImageFailureSurface({
    required this.width,
    required this.height,
    required this.errorLabel,
  });

  final double? width;
  final double? height;
  final String errorLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      liveRegion: true,
      label: errorLabel,
      child: Container(
        key: const ValueKey('exercise-image-fallback'),
        width: width,
        height: height,
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        alignment: Alignment.center,
        color: isDark ? AppColors.surfaceDarkElevated : AppColors.surfaceLight3,
        child: Icon(
          Icons.broken_image_outlined,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          size: 36,
        ),
      ),
    );
  }
}
