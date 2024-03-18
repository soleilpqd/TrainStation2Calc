import 'package:flutter/material.dart';
import 'package:image/image.dart';
import 'package:train_station_2_calc/crop_view.dart';
import 'package:train_station_2_calc/crop_mask_view.dart';
import 'package:train_station_2_calc/anti_confuse.dart';

class ImageCropPage extends StatefulWidget {

  final ImgImage image;
  final void Function(Rect?) onCompletion;

  const ImageCropPage({super.key, required this.image, required this.onCompletion});

  @override
  State<StatefulWidget> createState() => _ImageCropPageState();

}

class _ImageCropPageState extends State<ImageCropPage> {

  final CropMaskPainter _maskPainter = const CropMaskPainter(shape: CropMaskShape.rectangle, shapeRatio: 1, cropWindowBorder: 5);
  late CropViewAdapter _adapter;

  @override
  void initState() {
    super.initState();
    _adapter = CropViewAdapter(calculateCropWindow: (bounds) => _maskPainter.calculateCropWindow(bounds));
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
      body: CropView(
        adapter: _adapter,
        originWidth: widget.image.width.toDouble(),
        originHeight: widget.image.height.toDouble(),
        mask: CropMaskView(painter: _maskPainter),
        child: Container(
          color: Colors.red,
          child: FittedBox(fit: BoxFit.fill, child: UiImage.memory(encodeJpg(widget.image))),
        )
      )
    );
  }

  void _onBack() {
    Navigator.of(context).pop();
    widget.onCompletion(null);
  }

  void _onSubmit() {
    Rect cropFrame = _adapter.getCropFrame();
    Navigator.of(context).pop();
    widget.onCompletion(cropFrame);
  }

}
