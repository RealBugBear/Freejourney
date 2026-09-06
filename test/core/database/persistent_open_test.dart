import 'dart:io';
import 'package:corejourney/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'storage failure aborts startup instead of accepting nonpersistent writes',
      () async {
    await expectLater(AppDatabase.open(supportDirectory: () async {
      throw const FileSystemException('synthetic unavailable directory');
    }), throwsA(isA<FileSystemException>()));
  });
}
