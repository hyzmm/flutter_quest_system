import 'dart:async';

mixin EventDispatcher<T> {
  final StreamController<T> _controller =
      StreamController.broadcast(sync: true);

  bool get isDestroyed => _controller.isClosed;

  StreamSubscription on(Function(T) callback) =>
      _controller.stream.listen(callback);

  void dispatch(T data) {
    _controller.add(data);
  }

  void destroy() {
    _controller.close();
  }
}
