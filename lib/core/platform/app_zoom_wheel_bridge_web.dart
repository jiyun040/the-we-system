import 'dart:js_interop';

import 'package:web/web.dart' as web;

typedef AppZoomWheelHandler = void Function(double delta);
typedef AppZoomWheelDisposer = void Function();

AppZoomWheelDisposer registerAppZoomWheelHandler(AppZoomWheelHandler handler) {
  final listener = ((web.Event event) {
    final detail = (event as web.CustomEvent).detail?.dartify();
    if (detail is num) handler(detail.toDouble());
  }).toJS;

  web.window.addEventListener('the-we-app-zoom', listener);
  return () => web.window.removeEventListener('the-we-app-zoom', listener);
}
