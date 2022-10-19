import 'dart:async';

import 'package:flutter/services.dart';

class PerfectVolumeControl {
  /// Volume change monitor name
  static const String _volumeChangeListenerName = 'volumeChangeListener';

  static const MethodChannel _channel = MethodChannel('perfect_volume_control');

  /// Get the current volume of the device，
  /// This property is a simple way to write getvolume
  Future<double> get volume => getVolume();

  /// Volume change monitor flow
  final StreamController<double> _streamController =
      StreamController.broadcast();

  /// Get listener stream
  Stream<double> get stream => _streamController.stream;

  PerfectVolumeControl();

  /// method invoke handler
  Future<dynamic> _methodCallHandler(call) async {
    if (call.method == _volumeChangeListenerName) {
      final volume = call.arguments as double;
      _streamController.add(volume);
    }
  }

  /// Get the current volume of the device
  Future<double> getVolume() async {
    return await _channel.invokeMethod('getVolume');
  }

  /// Set the device volume according to [volume],
  /// and the volume range is 0.0 - 1.0
  Future<void> setVolume(double volume) async {
    assert(volume >= 0 && volume <= 1);
    return await _channel.invokeMethod('setVolume', {"volume": volume});
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
