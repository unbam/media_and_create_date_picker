import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:media_and_create_date_picker/media_and_create_date_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _path;
  MediaType _type;
  DateTime _createDate;
  Uint8List _videoThumbnail;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            RaisedButton(
              child: Text('Pick Media'),
              onPressed: () async {
                _init();

                final result = await MediaAndCreateDatePicker.pickMedia;
                if (result.type == MediaType.video) {
                  _videoThumbnail = await VideoThumbnail.thumbnailData(
                    video: result.path,
                    imageFormat: ImageFormat.JPEG,
                    maxWidth: 200,
                    quality: 20,
                  );
                }

                setState(() {
                  _path = result.path;
                  _createDate = result.createDate;
                  _type = result.type;
                });
              },
            ),
            Center(
              child: Text('Create Date: $_createDate'),
            ),
            _path != ''
                ? Center(
                    child: _type == MediaType.image
                        ? Image.file(
                            File(_path),
                            width: 200,
                          )
                        : Image.memory(_videoThumbnail),
                  )
                : SizedBox.shrink(),
            _path != ''
                ? Center(
                    child: Text(_path),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  void _init() {
    _path = '';
    _type = MediaType.unknown;
    _createDate = null;
    _videoThumbnail = null;
  }
}
