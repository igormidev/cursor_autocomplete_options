import 'dart:async';

class Debouncer {
  Timer? _timer;
  final Duration timerDuration;

  Debouncer({
    this.timerDuration = const Duration(seconds: 1),
  });

  final List<FutureOr<void> Function()> _onInitFuncs = [];
  final List<FutureOr<void> Function()> _onEndFuncs = [];

  Future<void> resetDebounce(FutureOr<void> Function() execute) async {
    _timer?.cancel();
    for (final func in _onInitFuncs) {
      await func();
    }

    _timer = Timer(timerDuration, () async {
      await execute();
      for (final func in _onEndFuncs) {
        await func();
      }
    });
  }

  /// Add a function that will be executed `after`
  /// the [resetDebounce] executable function
  void addOnEndFunction(void Function() func) {
    _onEndFuncs.add(func);
  }

  /// Add a function that will be executed `before`
  /// the [resetDebounce] executable function
  void addOnInitFunction(void Function() func) {
    _onInitFuncs.add(func);
  }

  void dispose() {
    _timer?.cancel();
  }
}
