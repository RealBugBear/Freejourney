/// Per-package completion questionnaire questions.
/// Fill in the 'de' and 'en' strings for each package as they become available.
/// Any package with a null or missing entry falls back to the default question.

const String _defaultDe =
    'Hattest du durch das Training eine verstärkte emotionale oder stressige Zeit '
    'und konntest dich mit diesen Themen konfrontieren – zu erkennen, dass deine '
    'emotionale Reaktion nicht immer mit der Realität übereinstimmt – und anfangen '
    'dich zu regulieren?';

const String _defaultEn =
    'During the training, did you experience a more intense emotional or stressful '
    'period? Were you able to face those themes, recognize that your emotional '
    'response did not always match the situation, and begin to regulate yourself?';

const Map<String, Map<String, String?>> _packageQuestions = {
  'moro': {
    'de': _defaultDe,
    'en': _defaultEn,
  },
  'spinal_galant': {
    'de': null, // TODO: add Spinal Galant specific question
    'en': null,
  },
  'tlr': {
    'de': null, // TODO: add TLR specific question
    'en': null,
  },
  'babkin': {
    'de': null,
    'en': null,
  },
  'such_saug': {
    'de': null,
    'en': null,
  },
  'atnr': {
    'de': null,
    'en': null,
  },
  'stnr': {
    'de': null,
    'en': null,
  },
  'babinski': {
    'de': null,
    'en': null,
  },
  'landau': {
    'de': null,
    'en': null,
  },
};

/// Returns the completion question for [packageId] in [languageCode].
/// Falls back to the default Moro question if no specific question is defined.
String completionQuestionFor(String packageId, String languageCode) {
  final lang = languageCode == 'en' ? 'en' : 'de';
  final specific = _packageQuestions[packageId]?[lang];
  if (specific != null && specific.isNotEmpty) return specific;
  return lang == 'en' ? _defaultEn : _defaultDe;
}
