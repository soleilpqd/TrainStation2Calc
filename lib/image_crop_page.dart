/*
MIT License

Copyright © 2024 DươngPQ

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

import 'package:flutter/material.dart';
import 'package:train_station_2_calc/crop_view.dart';
import 'package:train_station_2_calc/crop_mask_view.dart';
import 'package:train_station_2_calc/anti_confuse.dart';
import 'package:train_station_2_calc/isolations.dart';

class ImageCropPage extends StatefulWidget {

  final ImgImage image;
  final void Function(double, Rect?) onCompletion;

  const ImageCropPage({super.key, required this.image, required this.onCompletion});

  @override
  State<StatefulWidget> createState() => _ImageCropPageState();

}

class _ImageCropPageState extends State<ImageCropPage> {

  final CropMaskPainter _maskPainter = const CropMaskPainter(shape: CropMaskShape.rectangle, shapeRatio: 1, cropWindowBorder: 5);
  late CropViewAdapter _adapter;
  UiImage? _imageView;

  @override
  void initState() {
    super.initState();
    _adapter = CropViewAdapter(calculateCropWindow: (bounds) => _maskPainter.calculateCropWindow(bounds));
    Isolations.loadImageView(widget.image).then((value) => setState(() {
      _imageView = value;
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text("Image crop", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: _onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _onSubmit,
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: _imageView != null ?
        CropView(
          adapter: _adapter,
          originWidth: widget.image.width.toDouble(),
          originHeight: widget.image.height.toDouble(),
          mask: CropMaskView(painter: _maskPainter),
          child: FittedBox(fit: BoxFit.fill, child: _imageView!)
        ) :
        const Center(child: Wrap(children: [CircularProgressIndicator()]))
    );
  }

  void _onBack() {
    Navigator.of(context).pop();
    widget.onCompletion(0, null);
  }

  void _onSubmit() {
    (double, Rect) result = _adapter.getCropFrame();
    Navigator.of(context).pop();
    widget.onCompletion(result.$1, result.$2);
  }

}
