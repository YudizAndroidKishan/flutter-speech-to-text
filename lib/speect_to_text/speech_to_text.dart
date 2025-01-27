import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class SpeechToText {
  SpeechToText._() {
    _init();
  }

  static final SpeechToText _instance = SpeechToText._();

  static SpeechToText get instance => _instance;

  final _record = AudioRecorder();
  RxBool isRecording = false.obs;

  /// Mic permission status
  RxBool isMicPermissionGranted = false.obs;

  /// Max duration to record audio in seconds
  final int maxRecordingDuration = 6;

  late StreamSubscription<RecordState> _stateSubscription;
  late Timer _maxDurationTimer;

  /// Dispose the audio recorder.
  Future<void> dispose() async {
    await _record.dispose();
    _stateSubscription.cancel();
  }

  /// Initialize the speech to text module
  void _init() {
    _startStateChangeListener();
    _checkPermission();
  }

  /// Initialize the max duration timer
  void _initMaxDurationTimer() {
    _maxDurationTimer = Timer(
      Duration(seconds: maxRecordingDuration),
      () async {
        if (await _record.isRecording()) {
          log(
            'stopping the recording as max duration is reached',
            name: '_initMaxDurationTimer',
          );
          stopRecording();
        }
      },
    );
  }

  /// Start listening to the recording state for [isRecording] variable
  void _startStateChangeListener() {
    _stateSubscription = _record.onStateChanged().listen((state) {
      switch (state) {
        case RecordState.stop:
          _maxDurationTimer.cancel();
          isRecording.value = false;
          break;
        case RecordState.record:
          _initMaxDurationTimer();
          isRecording.value = true;
          break;
        case RecordState.pause:
          break;
      }
    });
  }

  /// Check mic permission and set the permission status in [isMicPermissionGranted] variable
  Future<void> _checkPermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      isMicPermissionGranted.value = true;
    } else {
      isMicPermissionGranted.value = true;
    }
  }

  /// stops recording and return the path of the audio file
  Future<void> stopRecording() async {
    final path = await _record.stop();
    log(path ?? 'no path', name: 'Path of audio');
  }

  /// Start recording audio after checking permission
  /// if permienatly denied redirect to settingsq
  Future<void> startRecording() async {
    if (isMicPermissionGranted.value) {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;
      await _record.start(
        const RecordConfig(
          noiseSuppress: true,
          echoCancel: true,
        ),
        path: '$tempPath/audio.m4a',
      );
    } else {
      await Permission.microphone
          .onDeniedCallback(openAppSettings)
          .onGrantedCallback(() {
            isMicPermissionGranted.value = true;
            startRecording();
          })
          .onPermanentlyDeniedCallback(openAppSettings)
          .request();
    }
  }
}
