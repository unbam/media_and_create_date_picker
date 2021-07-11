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
  late String path;
  DateTime? createDate;
  late MediaType mediaType;
  late ResultType resultType;
  late ErrorMessage error;

  MediaData();

  MediaData.fromJson(Map<String, dynamic> json) {
    path = json['path'];
    createDate = DateTime.tryParse(json["createDate"]);

    var mediaType = MediaType.unknown;
    switch (json["mediaType"]) {
      case 'image':
        mediaType = MediaType.image;
        break;
      case 'video':
        mediaType = MediaType.video;
        break;
      default:
        break;
    }
    this.mediaType = mediaType;

    var resultType = ResultType.none;
    switch (json["resultType"]) {
      case 'success':
        resultType = ResultType.success;
        break;
      case 'cancel':
        resultType = ResultType.cancel;
        break;
      case 'error':
        resultType = ResultType.error;
        break;
      default:
        break;
    }
    this.resultType = resultType;

    var errorMessage = ErrorMessage.none;
    switch (json["error"]) {
      case 'NOT_SUPPORTED':
        errorMessage = ErrorMessage.not_supported;
        break;
      case 'PERMISSION_DENIED':
        errorMessage = ErrorMessage.permission_denied;
        break;
      case 'PERMISSION_SELECTION_DENIED':
        errorMessage = ErrorMessage.permission_selection_denied;
        break;
      case '':
      default:
        break;
    }
    this.error = errorMessage;
  }
}

enum MediaType {
  unknown,
  image,
  video,
}

enum ResultType {
  none,
  success,
  cancel,
  error,
}

enum ErrorMessage {
  none,
  not_supported,
  permission_denied,
  permission_selection_denied,
}
