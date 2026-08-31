typedef AppZoomWheelHandler = void Function(double delta);
typedef AppZoomWheelDisposer = void Function();

AppZoomWheelDisposer registerAppZoomWheelHandler(AppZoomWheelHandler handler) =>
    () {};
