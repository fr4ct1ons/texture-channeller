import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:texture_channel_packer/imagePicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const MyHomePage(title: 'Texture Channeller'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _imageFirstPixel = "No file was selected";
  Uint8List _fileContent = Uint8List.fromList([0]);
  img.Image result = img.Image(2048, 2048);
  img.Image preview = img.Image(256, 256);

  List<int> encodedPng = [0, 0, 0];

  Image? previewWidget;

  int _width = 2048, _height = 2048;

  TextEditingController _wController = TextEditingController(text: "2048");
  TextEditingController _hController = TextEditingController(text: "2048");

  final List<ImagePicker> _picker = [
    ImagePicker(
      channel: ImageChannel.R,
    ),
    ImagePicker(
      channel: ImageChannel.G,
    ),
    ImagePicker(
      channel: ImageChannel.B,
    ),
    ImagePicker(
      channel: ImageChannel.A,
    )
  ];

  @protected
  @mustCallSuper
  void initState() {
    encodedPng = img.encodePng(preview);
  }

  void _generateImage() {
    const startingSnackBar = SnackBar(content: Text("Generating..."));
    ScaffoldMessenger.of(context).showSnackBar(startingSnackBar);

    //TODO: Move this to a different thread.
    _imageGeneration().then((value) {
      ScaffoldMessenger.of(context).clearSnackBars();

      const finishedSnackBar = SnackBar(content: Text("Generated!"));
      ScaffoldMessenger.of(context).showSnackBar(finishedSnackBar);
    });
  }

  Future<void> _imageGeneration() async {
    String hexColor = '00000000';
    result = img.Image(_width, _height);
    for (var y = 0; y < _height; y++) {
      for (var x = 0; x < _width; x++) {
        hexColor = _picker[3].getPixelFromChannel(x, y) +
            _picker[2].getPixelFromChannel(x, y) +
            _picker[1].getPixelFromChannel(x, y) +
            _picker[0].getPixelFromChannel(x, y);

        result.setPixelSafe(x, y, int.parse(hexColor, radix: 16));
      }
    }

    setState(() {
      encodedPng = img.encodePng(result);
    });
  }

  void _savePng() {
    FilePicker.platform.saveFile(
        dialogTitle: "Select where to save the file.",
        fileName: "Texture.png",
        type: FileType.custom,
        allowedExtensions: ['png']).then((value) {
      //
      String pathToSave = value!;
      File(pathToSave).writeAsBytesSync(encodedPng);

      SnackBar saved = const SnackBar(
        content: Text('Saved!'),
      );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(saved);
    });

    SnackBar saving = const SnackBar(
      content: Text('Saving...'),
      duration: Duration(seconds: 30),
    );
    ScaffoldMessenger.of(context).showSnackBar(saving);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 25),
            Image(
              image: MemoryImage(Uint8List.fromList(encodedPng)),
              height: 200,
              gaplessPlayback: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 100,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                      ],
                      decoration: const InputDecoration(labelText: "Width"),
                      controller: _wController,
                      onChanged: (value) {
                        int num = 0;
                        if (value.isNotEmpty) num = int.parse(value);

                        setState(() {
                          _width = num;
                        });
                      },
                    )),
                const SizedBox(
                  width: 10,
                ),
                Container(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    decoration: const InputDecoration(labelText: "Height"),
                    controller: _hController,
                    onChanged: (value) {
                      int num = 0;
                      if (value.isNotEmpty) num = int.parse(value);

                      setState(() {
                        _height = num;
                      });
                    },
                  ),
                )
              ],
            ),
            _picker[0],
            _picker[1],
            _picker[2],
            _picker[3],
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              child: Text("Generate"),
              onPressed: _generateImage,
            ),
            const SizedBox(
              height: 10,
            ),
            OutlinedButton(
              child: Text("Save PNG"),
              onPressed: _savePng,
            ),
            const Spacer(),
            const Text("Made by FR4CT1ONS."),
            const Text("lucena-fr4ct1ons.github.io"),
            const SizedBox(
              height: 12,
            )
          ],
        ),
      ),
    );
  }
}
