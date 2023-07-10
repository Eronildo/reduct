# Reduct

Uses atomic state to improve and simplify dart state management.

## Install

```yaml
dart pub add reduct
```

## Atoms

```dart
final counter = Atom(0);
final increment = Atom.action();
```

## Reducer

```dart
class CounterReducer extends Reducer {
  CounterReducer() {
    on(increment, (_) => counter.value++);
  }
}
```

## Observe Atoms

All atoms can be observed:

```dart
Disposer disposer = counter.addListener((value) {
    print(value);
});

disposer();
```