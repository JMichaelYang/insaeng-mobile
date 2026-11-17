import 'dart:async';

import 'package:flutter/services.dart';

class WidgetEventService {
  const new();

  static const channel = MethodChannel('com.jae.insaeng/widget_event');
  static const handleMethod = 'handle';
  static const readyMethod = 'ready';

  Future<void> listen(FutureOr<void> Function(Uri? uri) handler) {
    channel.setMethodCallHandler((call) async {
      if (call case MethodCall(method: handleMethod, arguments: final String uri)) {
        await handler(Uri.tryParse(uri));
        return null;
      }
      throw MissingPluginException();
    });
    return channel.invokeMethod<void>(readyMethod);
  }
}
