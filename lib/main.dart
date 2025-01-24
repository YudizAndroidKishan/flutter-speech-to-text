import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text_demo/speech_to_text/speech_to_text_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: SpeechToTextUtils.instance.textEditingController,
              maxLines: 10,
            ).paddingAll(20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (SpeechToTextUtils.instance.isListening.value) {
            SpeechToTextUtils.instance.stopListening();
          } else {
            SpeechToTextUtils.instance.startListening();
          }
        },
        tooltip: 'Increment',
        child: Obx(() => SpeechToTextUtils.instance.isListening.value
            ? const Text("Stop")
            : const Text("Start")),
      ),
    );
  }
}
