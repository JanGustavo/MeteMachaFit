import 'dart:js' as js;

class NotificationService {
  /// Solicita permissão para exibir notificações no navegador
  static void requestPermission() {
    try {
      if (js.context.hasProperty('Notification')) {
        final notification = js.context['Notification'];
        notification.callMethod('requestPermission');
      }
    } catch (_) {}
  }

  /// Exibe uma notificação nativa do navegador
  static void showNotification(String title, String body) {
    try {
      if (js.context.hasProperty('Notification')) {
        final notificationClass = js.context['Notification'];
        final permission = notificationClass['permission'];
        if (permission == 'granted') {
          js.JsObject(notificationClass, [
            title,
            js.JsObject.jsify({'body': body}),
          ]);
        } else if (permission == 'default') {
          requestPermission();
        }
      }
    } catch (_) {}
  }
}
