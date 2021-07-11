import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:heic_to_jpg/heic_to_jpg.dart';
import 'package:media_and_create_date_picker/media_and_create_date_picker.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _path;
  late String _errorMessage;
  late MediaType _type;
  late ResultType _resultType;
  DateTime? _createDate;
  Uint8List? _videoThumbnail;

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
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              RaisedButton(
                child: Text('Pick Media'),
                onPressed: () async {
                  _init();

                  final result = await MediaAndCreateDatePicker.pickMedia;
                  if (result.mediaType == MediaType.video) {
                    _videoThumbnail = await VideoThumbnail.thumbnailData(
                      video: result.path,
                      imageFormat: ImageFormat.JPEG,
                      maxWidth: 200,
                      quality: 20,
                    );
                  }

                  final extension = path.extension(result.path);
                  var filePath = '';
                  if (RegExp('.(heic|HEIC)').hasMatch(extension)) {
                    print('convert HeicToJpg');
                    var convert = await HeicToJpg.convert(result.path);
                    filePath = convert ?? '';
                  } else {
                    filePath = result.path;
                  }

                  setState(() {
                    _path = filePath;
                    _createDate = result.createDate;
                    _type = result.mediaType;
                    _resultType = result.resultType;
                    _errorMessage = result.error.toString();
                    print('mediaType: $_type');
                    print('resultType: $_resultType');
                    print('path: $_path');
                    print('createDate: $_createDate');
                    print('errorMessage: $_errorMessage');
                  });
                },
              ),
              Center(
                child: Text('Create Date: $_createDate'),
              ),
              Center(
                child: Text('ResultType: ${_resultType.toString()}'),
              ),
              Center(
                child: Text('MediaType: ${_type.toString()}'),
              ),
              Center(
                child: Text('Error Message: $_errorMessage'),
              ),
              _path != ''
                  ? Center(
                      child: _type == MediaType.image
                          ? Image.file(
                              File(_path),
                              width: 200,
                            )
                          : _videoThumbnail != null
                              ? Image.memory(_videoThumbnail!)
                              : SizedBox.shrink(),
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
      ),
    );
  }

  void _init() {
    _path = '';
    _type = MediaType.unknown;
    _resultType = ResultType.none;
    _createDate = null;
    _videoThumbnail = null;
    _errorMessage = '';
  }
}
