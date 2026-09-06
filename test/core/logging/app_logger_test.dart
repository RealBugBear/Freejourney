import 'package:corejourney/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _Output extends LogOutput {
  final lines = <String>[];
  @override
  void output(OutputEvent event) {
    lines.addAll(event.lines);
  }
}

void main() {
  test(
      'production console redacts messages and exception values but reports errors',
      () {
    final output = _Output();
    final logger = AppLogger(production: true, output: output);
    var reported = 0;
    logger.reportError = (_, __) {
      reported++;
    };
    logger.i('synthetic private info');
    logger.e('synthetic private message',
        error: StateError('synthetic secret'));
    expect(output.lines.join('\n'), isNot(contains('synthetic')));
    expect(output.lines.join('\n'), contains('StateError'));
    expect(reported, 1);
  });
}
