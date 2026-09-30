import 'dart:html' as html;

void showBrowserNotification({required String title, required String body}) {
  if (html.Notification.permission == 'granted') {
    html.Notification(title, body: body);
  }
}
