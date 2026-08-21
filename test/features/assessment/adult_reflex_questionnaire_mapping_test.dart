import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';

class _ExpectedAdultMapping {
  const _ExpectedAdultMapping({
    required this.role,
    required this.polarity,
    required this.reflexes,
    required this.filters,
  });

  final String role;
  final String polarity;
  final List<String> reflexes;
  final List<String> filters;
}

// Generated from adult_v3 Item-Mapping (Teil B.4). Do not edit by hand.
const expectedAdultV3Mappings = <String, _ExpectedAdultMapping>{
  's013': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babinski', 'plantar'], filters: []),
  's014': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant'], filters: []),
  's034': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro', 'flr'], filters: []),
  's035': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  's036': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  's087': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant'], filters: []),
  'a004': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr'], filters: []),
  'a011': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin'], filters: []),
  's001': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr', 'babinski'], filters: []),
  's004': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['plantar'], filters: []),
  's008': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr'], filters: []),
  's009': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr', 'stnr', 'righting'], filters: []),
  's012': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant', 'landau'], filters: []),
  's015': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babinski'], filters: []),
  's017': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant', 'stnr', 'amphibian'], filters: []),
  's018': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr', 'rootingSucking'], filters: []),
  's019': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant'], filters: []),
  's020': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr', 'landau'], filters: []),
  'a018': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['atnr'], filters: []),
  'a021': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['landau', 'righting'], filters: []),
  's022': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr'], filters: []),
  's023': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr', 'stnr', 'landau', 'plantar'], filters: []),
  's024': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant'], filters: []),
  's025': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin'], filters: []),
  's026': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['plantar'], filters: []),
  's028': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr', 'stnr'], filters: []),
  's029': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro', 'tlr', 'atnr', 'stnr'], filters: []),
  's030': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr', 'landau'], filters: ['swims']),
  's032': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr'], filters: []),
  'a025': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['atnr', 'stnr'], filters: ['screenWork']),
  'a027': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['atnr'], filters: ['screenWork']),
  'a033': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  'a036': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr', 'landau'], filters: ['deskWork']),
  's086': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr', 'moro', 'tlr'], filters: []),
  'a040': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['atnr'], filters: ['drives']),
  'a042': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['atnr'], filters: ['drives']),
  'a043': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr'], filters: ['ridesAsPassenger']),
  'a049': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr'], filters: []),
  's101': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babinski', 'plantar'], filters: []),
  'a052': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['righting'], filters: []),
  'a057': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['landau'], filters: []),
  'a058': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr'], filters: []),
  'a092': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['plantar'], filters: []),
  'a095': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babinski'], filters: []),
  's057': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin', 'rootingSucking'], filters: []),
  's058': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin', 'rootingSucking'], filters: []),
  's059': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin', 'rootingSucking'], filters: []),
  's060': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin', 'rootingSucking'], filters: []),
  's061': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin', 'plantar', 'palmar'], filters: ['handwriting']),
  's062': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin', 'plantar', 'palmar'], filters: []),
  's063': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr', 'babkin', 'plantar', 'palmar', 'rootingSucking'], filters: []),
  'a010': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['rootingSucking'], filters: []),
  'a094': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['rootingSucking'], filters: []),
  's066': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['babkin', 'palmar', 'righting'], filters: ['handwriting']),
  's068': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['righting', 'palmar'], filters: ['handwriting']),
  's069': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr', 'righting', 'palmar'], filters: ['handwriting']),
  's070': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr', 'righting', 'palmar'], filters: ['handwriting']),
  's072': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant', 'stnr', 'babkin', 'righting'], filters: ['handwriting']),
  's073': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['atnr'], filters: ['handwriting']),
  's074': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['atnr'], filters: ['handwriting']),
  'a068': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['palmar'], filters: ['toolUse']),
  'a074': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['stnr'], filters: ['handwriting']),
  's078': _ExpectedAdultMapping(role: 'context', polarity: 'd', reflexes: [], filters: []),
  's079': _ExpectedAdultMapping(role: 'context', polarity: 'd', reflexes: [], filters: []),
  's082': _ExpectedAdultMapping(role: 'context', polarity: 'd', reflexes: [], filters: []),
  's080': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr', 'moro', 'stnr'], filters: []),
  's081': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr', 'atnr', 'stnr'], filters: []),
  's084': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant', 'landau'], filters: []),
  's090': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr'], filters: []),
  'a029': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['atnr'], filters: []),
  's038': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr', 'moro'], filters: []),
  's039': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  's040': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro', 'atnr'], filters: []),
  's041': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['spinalGalant'], filters: []),
  's044': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  's050': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr', 'moro'], filters: []),
  's051': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  's052': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  's053': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro', 'flr'], filters: []),
  's055': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro', 'flr'], filters: []),
  's100': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr'], filters: []),
  'a076': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr'], filters: []),
  'a077': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr'], filters: []),
  'a079': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr'], filters: []),
  'a082': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['flr'], filters: []),
  's099': _ExpectedAdultMapping(role: 'context', polarity: 'd', reflexes: [], filters: []),
  's102': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['amphibian'], filters: []),
  'a088': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  'a089': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['tlr'], filters: []),
  'a090': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['moro'], filters: []),
  'a096': _ExpectedAdultMapping(role: 'score', polarity: 'd', reflexes: ['landau'], filters: []),
  's046': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: ['atnr', 'stnr'], filters: []),
  's094': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  's095': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  's096': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  's097': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  's098': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  'a126': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  'a127': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  'a128': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  'a129': _ExpectedAdultMapping(role: 'safety', polarity: 'd', reflexes: [], filters: []),
  's005': _ExpectedAdultMapping(role: 'movement', polarity: 'i', reflexes: ['flr', 'moro', 'tlr', 'atnr', 'babinski'], filters: ['afterSafetyCleared']),
  's006': _ExpectedAdultMapping(role: 'movement', polarity: 'i', reflexes: ['moro', 'flr', 'tlr', 'atnr', 'righting', 'babinski'], filters: ['afterSafetyCleared']),
};

void main() {
  test('every adult_v3 mapped ID matches role, polarity, reflexes and filters', () {
    final byId = {
      for (final question in adultSelfQuestionnaireV3.questions) question.id: question,
    };

    expect(expectedAdultV3Mappings.keys, hasLength(103));
    expect(byId.keys.where((id) => !id.startsWith('f_')), hasLength(103));

    for (final entry in expectedAdultV3Mappings.entries) {
      final question = byId[entry.key];
      expect(question, isNotNull, reason: 'missing ${entry.key}');
      final expected = entry.value;

      expect(question!.role.name, expected.role, reason: entry.key);
      expect(
        question.polarity == ReflexItemPolarity.inverse ? 'i' : 'd',
        expected.polarity,
        reason: entry.key,
      );
      expect(
        question.reflexes.map((reflex) => reflex.name).toList(),
        expected.reflexes,
        reason: entry.key,
      );
      expect(
        question.requiresFilters.map((filter) => filter.name).toList()..sort(),
        [...expected.filters]..sort(),
        reason: entry.key,
      );
      expect(
        question.textDe,
        isNot(equals('')),
        reason: '${entry.key} German text',
      );
    }
  });
}
