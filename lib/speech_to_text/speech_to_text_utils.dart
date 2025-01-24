import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:get/get.dart';

class SpeechToTextUtils {
  SpeechToTextUtils._() {
    _initSpeechToText();
  }
  static final SpeechToTextUtils _instance = SpeechToTextUtils._();
  static SpeechToTextUtils get instance => _instance;

  stt.SpeechToText speech = stt.SpeechToText();
  RxBool isSpeechToTextAvailable = false.obs;
  RxBool isListening = false.obs;
  TextEditingController textEditingController = TextEditingController();
  Timer? _speechTimer;

  /// Here in this method we are initializing the speech to text
  /// and setting the error and status listener
  Future<void> _initSpeechToText() async {
    isSpeechToTextAvailable.value = await stt.SpeechToText().initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
    log(
      'is STT available: ${isSpeechToTextAvailable.value}',
      name: 'SpeechToTextUtils._initSpeechToText',
    );
  }

  /// Here in this method we are handeling the error and
  /// displaying the snackbar and restarting the listening if required
  void _onError(SpeechRecognitionError error) {
    log('$error', name: 'SpeechToTextUtils._onError');

    String errorMessage = '';
    bool shouldRestartListening = false;

    switch (error.errorMsg) {
      case "error_no_match":
        errorMessage = 'No match found. Please try speaking again.';
        // shouldRestartListening = true; // Restart listening
        break;

      case "error_speech_timeout":
        errorMessage = 'No speech detected. Please try again.';
        shouldRestartListening = true; // Restart listening
        break;

      case "error_audio_error":
        errorMessage = 'Audio error detected. Restarting...';
        shouldRestartListening = true; // Restart listening after audio issue
        break;

      case "error_network":
      case "error_network_timeout":
        errorMessage = 'Network error. Please check your internet connection.';
        break;

      case "error_permission":
        errorMessage =
            'Microphone permission denied. Please enable it in settings.';
        break;

      case "error_busy":
        errorMessage = 'Recognizer is busy. Please wait and try again.';
        break;

      case "error_language_not_supported":
      case "error_language_unavailable":
        errorMessage =
            'The selected language is not supported. Please try another language.';
        break;

      case "error_server":
      case "error_server_disconnected":
        errorMessage = 'Server error occurred. Please try again later.';
        break;

      case "error_too_many_requests":
        errorMessage = 'Too many requests. Please wait and try again.';
        break;

      case "error_client":
        errorMessage =
            'A client-side error occurred. Please try restarting the app.';
        break;

      default:
        errorMessage = 'An unknown error occurred. Please try again.';
    }

    // Show user feedback
    Get.rawSnackbar(message: errorMessage);

    // Restart listening if applicable
    if (shouldRestartListening) {
      startListening();
    }
  }

  /// from this method we are managing the state for listening varaiable
  void _onStatus(String status) {
    log(status, name: 'SpeechToTextUtils._onStatus');
    if (status == 'done') {
      isListening.value = false;
    } else if (status == 'listening') {
      isListening.value = true;
    }
  }

  /// Here in this method we are stopping the speech to text
  /// and setting the listening to false
  Future<void> stopListening() async {
    await speech.stop();
    log('stopped listening', name: 'SpeechToTextUtils.stopListening');
  }

  /// Here in this method we are starting the speech to text
  /// and setting the error and status listener
  Future<void> startListening() async {
    try {
      await _initSpeechToText();
      if (!isSpeechToTextAvailable.value) {
        return;
      }
      await speech.listen(
        onResult: _onResult,
        localeId: 'hi_IN',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(milliseconds: 3000),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          autoPunctuation: true,
        ),
      );
    } catch (e) {
      log('$e', name: 'SpeechToTextUtils.startListening');
    }
  }

  /// Here in this method we are getting the result from the speech to text
  /// and updating the text editing controller
  void _onResult(SpeechRecognitionResult result) {
    log('${result.confidence}', name: 'confidence');
    textEditingController.text = result.recognizedWords;
  }
}
