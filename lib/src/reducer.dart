import 'dart:async';

import 'atom.dart';

/// The class responsible for making business decisions
/// to perform actions and modify Atoms;
/// ```dart
///
/// final counterState = Atom(0);
/// final incrementAction = Atom.action();
///
/// class CounterReducer extends Reducer {
///
///   CounterReducer() {
///     on(incrementAction, _increment);
///   }
///
///   void _increment(_) {
///     counterState.value++;
///   }
/// }
///
/// // in widget:
/// ...
/// onPressed: () => incrementAction();
/// ```
abstract class Reducer {
  final _disposers = <Disposer>[];

  /// Subscribe atoms:
  /// ```dart
  /// on(incrementAction, (_) => counterState.value++);
  /// ```
  void on<T>(
    Atom<T> atom,
    FutureOr<void> Function(T value) reducer,
  ) {
    final disposer = atom.addListener(reducer);
    _disposers.add(disposer);
  }

  /// Dispose all listeners.
  void dispose() {
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }
}
