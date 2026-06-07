import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gym_tracker/core/services/audio_service.dart';

class FakeAudioPlayer extends AudioPlayer {
  int playCalls = 0;
  int stopCalls = 0;
  Source? lastSource;

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playCalls++;
    lastSource = source;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Mock global channel de audioplayers
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async {
        return null;
      },
    );
    // Mock channel individual de audioplayers
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  late AudioService audioService;
  late FakeAudioPlayer fakePlayer;

  setUp(() {
    audioService = AudioService();
    fakePlayer = FakeAudioPlayer();
    audioService.setPlayer(fakePlayer);
    audioService.setAudioAvailable(true);
  });

  test('beep plays 1 time (salvar série)', () async {
    await audioService.beep();
    expect(fakePlayer.playCalls, 1);
    expect(fakePlayer.stopCalls, 1);
    expect(fakePlayer.lastSource, isA<AssetSource>());
    expect((fakePlayer.lastSource as AssetSource).path, 'sounds/beep.mp3');
  });

  test('restEnd plays 2 times (cronômetro descanso)', () async {
    await audioService.restEnd();
    expect(fakePlayer.playCalls, 2);
    expect(fakePlayer.stopCalls, 2);
  });

  test('workoutDone plays 3 times (finalizar treino)', () async {
    await audioService.workoutDone();
    expect(fakePlayer.playCalls, 3);
    expect(fakePlayer.stopCalls, 3);
  });
}
