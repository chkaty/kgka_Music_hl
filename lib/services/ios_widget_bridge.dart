import 'package:flutter/services.dart';

class IosWidgetBridge {
  IosWidgetBridge._();

  static final IosWidgetBridge instance = IosWidgetBridge._();
  static const MethodChannel _channel = MethodChannel('kgka_music_hl/widget');

  Future<void> syncPlaybackState(Map<String, dynamic>? state) async {
    await _channel.invokeMethod<void>('syncPlaybackState', state);
  }

  Future<String?> consumePendingAction() async {
    return _channel.invokeMethod<String?>('consumePendingWidgetAction');
  }
}
