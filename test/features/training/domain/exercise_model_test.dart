import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal valid row fixture — only fields required by fromRow().
Map<String, dynamic> _baseRow({
  String? imageUrl,
  String? duoImageUrl,
  String? videoUrl,
}) =>
    {
      'id': 'test_ex',
      'package_id': 'test',
      'sequence_number': 1,
      'title_de': 'Test',
      'title_en': 'Test',
      'position_instructions_de': <String>[],
      'position_instructions_en': <String>[],
      'movement_instructions_de': <String>[],
      'movement_instructions_en': <String>[],
      'execution_guide_de': '',
      'execution_guide_en': '',
      'duration_seconds': 7,
      'repetitions': 1,
      'image_path': 'assets/images/test.png',
      'image_url': imageUrl,
      'duo_image_url': duoImageUrl,
      'video_url': videoUrl,
    };

void main() {
  group('Exercise.fromRow — URL normalization', () {
    test('null URLs stay null', () {
      final ex = Exercise.fromRow(_baseRow());
      expect(ex.imageUrl, isNull);
      expect(ex.duoImageUrl, isNull);
      expect(ex.videoUrl, isNull);
    });

    test('valid URLs are preserved', () {
      const url = 'https://example.com/img.jpg';
      final ex = Exercise.fromRow(
          _baseRow(imageUrl: url, duoImageUrl: url, videoUrl: url));
      expect(ex.imageUrl, url);
      expect(ex.duoImageUrl, url);
      expect(ex.videoUrl, url);
    });

    test('empty string URLs are normalised to null', () {
      final ex = Exercise.fromRow(
          _baseRow(imageUrl: '', duoImageUrl: '', videoUrl: ''));
      expect(ex.imageUrl, isNull);
      expect(ex.duoImageUrl, isNull);
      expect(ex.videoUrl, isNull);
    });

    test('whitespace-only URLs are normalised to null', () {
      final ex = Exercise.fromRow(
          _baseRow(imageUrl: '   ', duoImageUrl: '\t', videoUrl: ' '));
      expect(ex.imageUrl, isNull);
      expect(ex.duoImageUrl, isNull);
      expect(ex.videoUrl, isNull);
    });

    test('URLs with leading/trailing whitespace are trimmed', () {
      const url = 'https://example.com/img.jpg';
      final ex = Exercise.fromRow(
          _baseRow(imageUrl: '  $url  ', duoImageUrl: ' $url', videoUrl: '$url '));
      expect(ex.imageUrl, url);
      expect(ex.duoImageUrl, url);
      expect(ex.videoUrl, url);
    });
  });

  group('Exercise.imageUrlFor', () {
    test('returns null when both URLs are null', () {
      final ex = Exercise.fromRow(_baseRow());
      expect(ex.imageUrlFor(), isNull);
      expect(ex.imageUrlFor(duo: true), isNull);
    });

    test('returns imageUrl for non-duo request', () {
      const url = 'https://example.com/solo.jpg';
      final ex = Exercise.fromRow(_baseRow(imageUrl: url));
      expect(ex.imageUrlFor(), url);
    });

    test('returns duoImageUrl when duo=true and duoImageUrl is set', () {
      const solo = 'https://example.com/solo.jpg';
      const duo = 'https://example.com/duo.jpg';
      final ex = Exercise.fromRow(_baseRow(imageUrl: solo, duoImageUrl: duo));
      expect(ex.imageUrlFor(duo: true), duo);
    });

    test('falls back to imageUrl when duo=true but duoImageUrl is null', () {
      const solo = 'https://example.com/solo.jpg';
      final ex = Exercise.fromRow(_baseRow(imageUrl: solo));
      expect(ex.imageUrlFor(duo: true), solo);
    });

    test('returns null for duo=true when both URLs are null', () {
      final ex = Exercise.fromRow(_baseRow());
      expect(ex.imageUrlFor(duo: true), isNull);
    });
  });
}
