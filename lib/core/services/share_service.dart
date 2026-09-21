import 'package:flutter/services.dart';

class SharedData {
  final String dataType; // 'text' | 'image'
  final String? text;
  final String? imagePath;

  const SharedData({required this.dataType, this.text, this.imagePath});
}

class ShareService {
  static const _channel = MethodChannel('com.elmahdi.qeeda/share');
  static ShareService? _instance;

  ShareService._();

  static ShareService get instance {
    _instance ??= ShareService._();
    return _instance!;
  }

  void Function(SharedData)? onNewShare;

  void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewShare') {
        final data = _parseData(call.arguments as Map?);
        if (data != null) onNewShare?.call(data);
      }
    });
  }

  Future<SharedData?> getInitialShare() async {
    try {
      final result = await _channel.invokeMethod<Map>('getSharedData');
      return _parseData(result);
    } catch (_) {
      return null;
    }
  }

  SharedData? _parseData(Map? raw) {
    if (raw == null) return null;
    final type = raw['type'] as String?;
    if (type == 'text') {
      final text = raw['text'] as String?;
      if (text != null && text.isNotEmpty) {
        return SharedData(dataType: 'text', text: text);
      }
    } else if (type == 'image') {
      final path = raw['path'] as String?;
      if (path != null && path.isNotEmpty) {
        return SharedData(dataType: 'image', imagePath: path);
      }
    }
    return null;
  }
}
