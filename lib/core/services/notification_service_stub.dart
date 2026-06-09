class NotificationService {
  /// Solicita permissão para exibir notificações (stub para plataformas não-web)
  static void requestPermission() {}

  /// Exibe uma notificação nativa (stub para plataformas não-web)
  static void showNotification(String title, String body) {}

  /// Abre a tela do treino ativo (stub para plataformas não-web)
  static void openActiveWorkout() {}

  Future<void> init() async {}
  Future<void> showRestTimer(int secondsLeft) async {}
  Future<void> showRestEnded() async {}
  Future<void> cancelNotification() async {}
  Future<void> showMusicNotification(String channelName, bool isPlaying) async {}
  Future<void> cancelMusicNotification() async {}
}
