import 'package:reduct/reduct.dart';
import 'package:test/test.dart';

final counterState = Atom(0);

final incrementAction = Atom.action();
final setNewCounterAction = Atom(0);

class CounterReducer extends Reducer {
  CounterReducer() {
    on(incrementAction, (_) => counterState.value++);
    on<int>(setNewCounterAction, (value) => counterState.setValue(value));
  }
}

void main() {
  late CounterReducer counterReducer;

  setUp(() {
    counterState.setValue(0);
    counterReducer = CounterReducer();
  });

  tearDown(() => counterReducer.dispose());

  test('increment counter', () {
    expect(counterState.value, 0);
    incrementAction();
    expect(counterState.value, 1);
  });

  test('set new counter', () {
    expect(counterState.value, 0);
    setNewCounterAction(10);
    expect(counterState.value, 10);
  });
}
