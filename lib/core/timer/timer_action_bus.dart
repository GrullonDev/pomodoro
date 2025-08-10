import 'dart:async';

/// Simple singleton event bus for notification action -> timer control.
class TimerActionBus {
  TimerActionBus._();
  static final TimerActionBus instance = TimerActionBus._();
  final _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;
  void add(String action) {
    if (!_controller.isClosed) _controller.add(action);
  }

  void dispose() => _controller.close();
}
