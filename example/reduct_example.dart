import 'package:reduct/reduct.dart';

void main() {
  // initialize the reducer
  CounterReducer();

  // call increment twice
  incrementAction();
  incrementAction();

  // outputs:
  // My counter: 1
  // My counter: 2
}

// atoms
final counterState = Atom(0);
final incrementAction = Atom.action();

// reducer
class CounterReducer extends Reducer {
  CounterReducer() {
    on(incrementAction, (_) => counterState.value++);
    on(counterState, (value) => print('My counter: $value'));
  }
}
