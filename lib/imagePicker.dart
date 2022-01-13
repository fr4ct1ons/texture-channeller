import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

enum ImageChannel { R, G, B, A }

class ImagePicker extends StatefulWidget {
  ImagePicker({Key? key, required this.channel}) : super(key: key);

  img.Image? currentImage;
  ImageChannel channel;

  int _constant = 127;
  String _currentOption = "Constant";
  String _selectedChannel = 'R';

  String getPixelFromChannel(int x, int y) {
    if (_currentOption == 'Constant') {
      return _constant.toRadixString(16);
    }

    if (x < 0) {
      x = 0;
    } else if (x >= currentImage!.width) {
      x = currentImage!.width - 1;
    }

    if (y < 0) {
      y = 0;
    } else if (y >= currentImage!.height) {
      y = currentImage!.height - 1;
    }
    String pixel = '00000000';
    try {
      pixel = currentImage!.getPixelSafe(x, y).toRadixString(16);
    } catch (e) {
      print(e);
    }

    if (_selectedChannel == 'R') {
      return pixel[6] + pixel[7];
    } else if (_selectedChannel == 'G') {
      return pixel[4] + pixel[5];
    } else if (_selectedChannel == 'B') {
      return pixel[2] + pixel[3];
    } else if (_selectedChannel == 'A') {
      return pixel[0] + pixel[1];
    }

    return _constant.toRadixString(16);
  }

  @override
  _ImagePickerState createState() => _ImagePickerState();
}

final List<Color> colorMap = [
  Colors.red.shade100,
  Colors.green.shade100,
  Colors.blue.shade100,
  Colors.grey.shade200,
];

class _ImagePickerState extends State<ImagePicker> {
  String _loadedFileName = "", _loadedFilePath = "";
  bool _invertImage = false;

  List<String> options = ["Constant", "From image"];

  @protected
  @mustCallSuper
  void initState() {
    widget._selectedChannel = widget.channel.name;
  }

  Widget _buildConstantSlider() {
    int constant = widget._constant;

    return Row(
      children: [
        Slider(
            value: widget._constant.toDouble(),
            label: "$widget._constant",
            min: 0,
            max: 255,
            onChanged: (value) {
              setState(() {
                widget._constant = value.floor();
              });
            }),
        Text("$constant".padLeft(3, '0'))
      ],
    );
  }

  Widget _buildPickedImage() {
    return Row(
      children: [
        Text(
          "$_loadedFileName",
          maxLines: 1,
        ),
        const SizedBox(
          width: 10,
        ),
        DropdownButton<String>(
          items: <String>['R', 'G', 'B', 'A'].map((e) {
            return DropdownMenuItem<String>(
              child: Text(e),
              value: e,
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              widget._selectedChannel = value!;
            });
          },
          value: widget._selectedChannel,
        ),

        //TODO: Add this in the future
        /*Checkbox(
          value: _invertImage,
          onChanged: (value) {
            setState(() {
              _invertImage = value!;
            });
          },
        ),
        Text("Invert"),*/
      ],
    );
  }

  Future<PlatformFile> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['png']);

    if (result == null) return PlatformFile(name: "", size: 0);

    PlatformFile file = result.files.first;
    return file;
  }

  void _readImage() {
    File imgFile = File(_loadedFilePath);

    setState(() {
      widget.currentImage = img.decodePng(imgFile.readAsBytesSync());
    });
  }

  @override
  Widget build(BuildContext context) {
    String label = '';

    switch (widget.channel) {
      case ImageChannel.R:
        label = "Red channel";
        break;
      case ImageChannel.G:
        label = "Green channel";
        break;
      case ImageChannel.B:
        label = "Blue channel";
        break;
      case ImageChannel.A:
        label = "Alpha channel";
        break;
      default:
    }

    Color bg = Colors.white;

    switch (widget.channel) {
      case ImageChannel.R:
        Color bg = Colors.red.shade300;
        break;
      case ImageChannel.G:
        Color bg = Colors.green.shade300;
        break;
      case ImageChannel.B:
        Color bg = Colors.blue.shade300;
        break;
      case ImageChannel.A:
        Color bg = Colors.grey.shade300;
        break;
      default:
    }

    return Container(
      color: colorMap[widget.channel.index],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          DropdownButton<String>(
            items: <String>['Constant', 'From image'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (val) {
              if (val == "From image") {
                _pickFile().then((value) {
                  if (value.name.isEmpty) {
                    return;
                  } else {
                    setState(() {
                      widget._currentOption = val!;
                      _loadedFileName = value.name;
                      _loadedFilePath = value.path!;
                    });

                    _readImage();
                  }
                });
              } else {
                setState(() {
                  widget._currentOption = val!;
                });
              }
            },
            value: widget._currentOption,
          ),
          const SizedBox(
            width: 5,
          ),
          widget._currentOption == "Constant"
              ? _buildConstantSlider()
              : _buildPickedImage()
        ],
      ),
    );
  }
}
