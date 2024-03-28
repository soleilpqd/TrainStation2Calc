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

import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:train_station_2_calc/anti_confuse.dart';
import 'package:vector_math/vector_math_64.dart';

class Isolations {

  static Future<UiImage> loadImageView(ImgImage image) => compute((argImg) => UiImage.memory(encodePng(argImg)), image);

  static Future<ImgImage?> loadImageFromXFile(XFile file) => compute((argFile) async {
    Uint8List data = await argFile.readAsBytes();
    return decodeImage(data);
  }, file);

  static Future<ImgImage?> loadImageFromFile(File file) => compute((argFile) async {
    Uint8List data = await argFile.readAsBytes();
    return decodeImage(data);
  }, file);

  static Future<ImgImage?> loadImageFromData(Uint8List data) => compute((argFile) => decodeImage(argFile), data);

  static Future<ImgImage?> cropResizeImage(ImgImage image, double angle, Rect? cropFrame) => compute((args) async {
    ImgImage image = args.$1;
    double angle = args.$2;
    Rect? frame = args.$3;
    if (frame != null) {
      if (angle != 0) {
        image = copyRotate(image, angle: degrees(angle));
      }
      ImgImage cropImage = copyCrop(
        image,
        x: frame.left.toInt(),
        y: frame.top.toInt(),
        width: frame.width.toInt(),
        height: frame.height.toInt()
      );
      return copyResize(cropImage, height: 50);
    }
    return copyResize(args.$1, height: 50);
  }, (image, angle, cropFrame));

}
