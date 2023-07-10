import 'dart:async';
import 'dart:collection';

/// A listener that can be added to a [Atom] using
/// [Atom.addListener].
///
/// This callback receives the current [Atom.value] as a parameter.
typedef Listener<T> = void Function(T value);

/// A callback that can be used to dispose a listener added with
/// [Atom.addListener].
typedef Disposer = void Function();

/// A callback that can be passed to [Atom.onError].
///
/// This callback should not throw.
typedef ErrorListener = void Function(Object error, StackTrace? stackTrace);

/// An observable class that stores a single [value].
///
/// ## Example: Counter
///
/// ```dart
/// final counterState = Atom(0);
/// ```
///
/// ```dart
/// void main() {
///   counterState.value++;
///   counterState.addListener((value) => print(value));
/// }
/// ```
///
/// See also:
///
/// - [addListener], to manually listen to a [Atom]
/// - [value], to read and update the value.
class Atom<T> {
  /// Initialize [value].
  Atom(this._value);

  T _value;
  bool _mounted = true;
  bool _debugCanAddListeners = true;
  final _listeners = LinkedList<_ListenerEntry<T>>();

  /// A callback for error reporting if one of the listeners added with [addListener] throws.
  ///
  /// This callback should not throw.
  ErrorListener? onError;

  bool _debugSetCanAddListeners(bool value) {
    assert(
      () {
        _debugCanAddListeners = value;

        return true;
      }(),
      '',
    );

    return true;
  }

  bool _debugIsMounted() {
    assert(
      () {
        if (!_mounted) {
          throw StateError('''
Tried to use $runtimeType after `dispose` was called.

Consider checking `mounted`.
''');
        }

        return true;
      }(),
      '',
    );

    return true;
  }

  static Atom<NoValue> action() => Atom(noValue);

  /// To be used like a method, is the same as update the [value].
  ///
  /// This will call all the listeners.
  void call([T? newValue]) => value = newValue ?? this._value;

  /// Whether [dispose] was called or not.
  bool get mounted => _mounted;

  /// The current "value" of this [Atom].
  ///
  /// Updating this variable will synchronously call all the listeners.
  T get value {
    assert(_debugIsMounted(), '');

    return _value;
  }

  /// Update the value.
  // Same as atom.value = newValue.
  // ignore: use_setters_to_change_properties
  void setValue(T newValue) {
    value = newValue;
  }

  set value(T value) {
    assert(_debugIsMounted(), '');

    _value = value;

    final errors = <Object>[];
    final stackTraces = <StackTrace?>[];
    for (final listenerEntry in _listeners) {
      try {
        listenerEntry.listener(value);
      } catch (error, stackTrace) {
        errors.add(error);
        stackTraces.add(stackTrace);

        if (onError != null) {
          onError?.call(error, stackTrace);
        } else {
          Zone.current.handleUncaughtError(error, stackTrace);
        }
      }
    }
    if (errors.isNotEmpty) {
      throw AtomListenerError._(errors, stackTraces, this);
    }
  }

  /// If a listener has been added using [addListener] and hasn't been removed yet.
  bool get hasListeners {
    assert(_debugIsMounted(), '');

    return _listeners.isNotEmpty;
  }

  /// Subscribes to this object.
  ///
  /// The [listener] callback will not be called immediately.
  /// Set [fireImmediately] to true if you want immediate execution of the [listener].
  ///
  /// To remove this [listener], call the function returned by [addListener]:
  ///
  /// ```dart
  /// final counter = Atom(0);
  /// final removeListener = counter.addListener((value) => ...);
  /// removeListener();
  /// ```
  ///
  /// Listeners cannot add other listeners.
  ///
  /// Adding and removing listeners has a constant time-complexity.
  Disposer addListener(
    Listener<T> listener, {
    bool fireImmediately = false,
  }) {
    assert(() {
      if (!_debugCanAddListeners) {
        throw ConcurrentModificationError();
      }

      return true;
    }(), '');
    assert(_debugIsMounted(), '');
    final listenerEntry = _ListenerEntry(listener);
    _listeners.add(listenerEntry);
    try {
      assert(_debugSetCanAddListeners(false), '');
      if (fireImmediately) {
        listener(value);
      }
    } catch (err, stack) {
      listenerEntry.unlink();
      onError?.call(err, stack);
      rethrow;
    } finally {
      assert(_debugSetCanAddListeners(true), '');
    }

    return () {
      if (listenerEntry.list != null) {
        listenerEntry.unlink();
      }
    };
  }

  /// Frees all the resources associated with this object.
  ///
  /// This marks the object as no longer usable and will make all methods/properties
  /// besides [mounted] inaccessible.
  void dispose() {
    assert(_debugIsMounted(), '');
    _listeners.clear();
    _mounted = false;
  }
}

/// No value object.
class NoValue {
  /// Void return.
  const NoValue();
}

/// No value instance.
const noValue = NoValue();

/// An error thrown when trying to update the value of a [Atom],
/// but at least one of the listeners threw.
final class AtomListenerError extends Error {
  AtomListenerError._(
    this.errors,
    this.stackTraces,
    this.atom,
  ) : assert(
          errors.length == stackTraces.length,
          'errors and stackTraces must match',
        );

  final List<Object> errors;

  final List<StackTrace?> stackTraces;

  final Atom<Object?> atom;

  @override
  String toString() {
    final buffer = StringBuffer();

    for (var index = 0; index < errors.length; index++) {
      final error = errors[index];
      final stackTrace = stackTraces[index];

      buffer
        ..writeln(error)
        ..writeln(stackTrace);
    }

    return '''
At least listener of the Atom $atom threw an exception
when the atom tried to update its value.

The exceptions thrown are:

$buffer
''';
  }
}

final class _ListenerEntry<T> extends LinkedListEntry<_ListenerEntry<T>> {
  _ListenerEntry(this.listener);

  final Listener<T> listener;
}
