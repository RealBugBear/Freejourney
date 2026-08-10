// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RejectingSharedPreferencesStore extends InMemorySharedPreferencesStore {
  RejectingSharedPreferencesStore({
    this.rejectWrites = false,
    this.rejectRemovals = false,
    this.rejectedWritesRemaining = 0,
  }) : super.empty();

  final bool rejectWrites;
  final bool rejectRemovals;
  int rejectedWritesRemaining;
  int setValueCalls = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    setValueCalls++;
    if (rejectWrites || rejectedWritesRemaining > 0) {
      if (rejectedWritesRemaining > 0) rejectedWritesRemaining--;
      return Future<bool>.value(false);
    }
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) {
    if (rejectRemovals) return Future<bool>.value(false);
    return super.remove(key);
  }
}

RejectingSharedPreferencesStore installRejectingSharedPreferencesStore({
  bool rejectWrites = false,
  bool rejectRemovals = false,
  int rejectNextWrites = 0,
}) {
  final store = RejectingSharedPreferencesStore(
    rejectWrites: rejectWrites,
    rejectRemovals: rejectRemovals,
    rejectedWritesRemaining: rejectNextWrites,
  );
  SharedPreferencesStorePlatform.instance = store;
  SharedPreferences.resetStatic();
  return store;
}
