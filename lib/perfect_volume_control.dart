import 'dart:async';

import 'package:flutter/services.dart';

enum VolumeKey { up, down }

class _VolumeKeySerializer {
  static String serialize(VolumeKey key) {
    switch (key) {
      case VolumeKey.up:
        return 'up';
      case VolumeKey.down:
        return 'down';
    }
  }

  static VolumeKey? deserialize(String value) {
    switch (value) {
      case 'up':
        return VolumeKey.up;
      case 'down':
        return VolumeKey.down;
      default:
        return null;
    }
  }
}

class PerfectVolumeControl {
  /// Volume change monitor name
  static const String _volumeKeyPressedName = 'volumeKeyPressed';

  static const MethodChannel _channel = MethodChannel('perfect_volume_control');

  final MethodChannel channel;

  /// Volume change monitor flow
  final StreamController<VolumeKey> _streamController =
      StreamController.broadcast();

  /// Get listener stream
  Stream<VolumeKey> get stream => _streamController.stream;

  PerfectVolumeControl([
    MethodChannel? customMethodChannel,
  ]) : channel = customMethodChannel ?? _channel;

  /// method invoke handler
  Future<dynamic> _methodCallHandler(call) async {
    if (call.method == _volumeKeyPressedName) {
      final volume = call.arguments as String;
      final key = _VolumeKeySerializer.deserialize(volume);

      if (key != null) {
        _streamController.add(key);
      }
    }
  }

  /// Set the device volume according to [volume],
  /// and the volume range is 0.0 - 1.0
  Future<void> setVolumeBounds({
    bool shouldKeep = false,
    double lower = 0.0,
    double upper = 1.0,
  }) async {
    assert(lower >= 0.0 && lower <= 1.0);
    assert(upper >= 0.0 && upper <= 1.0);
    assert(lower <= upper);

    await _channel.invokeMethod('setVolumeBounds', {
      'shouldKeep': shouldKeep,
      'lower': lower,
      'upper': upper,
    });
  }

  /// Hide or show according to [hide]
  Future<void> hideUI(bool hide) async {
    await _channel.invokeMethod('hideUI', {"hide": hide});
  }

  Future<void> startListeningVolume() async {
    _channel.setMethodCallHandler(_methodCallHandler);
    await _channel.invokeMethod('startListeningVolume');
  }

  Future<void> stopListeningVolume() async {
    await _channel.invokeMethod('stopListeningVolume');
  }

  void dispose() {
    stopListeningVolume();
    _streamController.close();
  }
}
