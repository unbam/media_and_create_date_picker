import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class MediaAndCreateDatePicker {
  static const MethodChannel _channel =
      const MethodChannel('media_and_create_date_picker');

  static Future<MediaData> get pickMedia async {
    final jsonStr = await _channel.invokeMethod('pickMedia');
    final jsonMap = json.decode(jsonStr);
    return MediaData.fromJson(jsonMap);
  }
}

class MediaData {
  String path;
  DateTime createDate;
  MediaType type;

  MediaData();

  MediaData.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    createDate = DateTime.tryParse(json["createDate"]);

    var mediaType = MediaType.unknown;
    switch (json["type"]) {
      case 'image':
        mediaType = MediaType.image;
        break;
      case 'video':
        mediaType = MediaType.video;
        break;
      default:
        break;
    }
    type = mediaType;
  }
}

enum MediaType {
  unknown,
  image,
  video,
}
