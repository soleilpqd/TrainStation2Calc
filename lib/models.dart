/*
  Train Station 2 Calculator - Simple resource calculator to play TrainStation2
  Copyright © 2024 SoleilPQD

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

final Image _defaultIcon = Image.asset("assets/icons/Icon_404.png", width: 50, height: 50);

Image loadIcon(String? name, Uint8List? blob) {
  if (blob != null) {
    return Image.memory(blob, width: 50, height: 50);
  }
  if (name != null && name.isNotEmpty) {
    return Image.asset("assets/icons/$name", width: 50, height: 50, errorBuilder: (context, error, stackTrace) => _defaultIcon);
  }
  return _defaultIcon;
}

class TableIndex {

  int section = 0;
  int? row;

  TableIndex({required int index, required List<int> sectionLengths}) {
    int section_ = 0;
    int row_ = -1;
    int temp = index;
    int lIdx = 0;
    while (temp >= 0 && lIdx < sectionLengths.length) {
      temp -= sectionLengths[lIdx] + 1;
      lIdx += 1;
      if (temp >= 0) {
        section_ += 1;
      }
    }
    temp = 0;
    for (int idx = 0; idx < section_; idx += 1) {
      temp += sectionLengths[idx] + 1;
    }
    row_ = index - temp - 1;
    section = section_;
    row = row_ >= 0 ? row_ : null;
  }

  static int getNumberOrRows(List<int> sectionLengths) {
    int numOfRows = sectionLengths.length;
    for (int item in sectionLengths) {
      numOfRows += item;
    }
    return numOfRows;
  }

}

/// Mining material
class Resource {
  String name;
  bool enable;
  /// Time (seconds) to mine
  int time;
  int level;
  String? icon;
  Uint8List? iconBlob;

  Resource({
    required this.name,
    required this.enable,
    required this.time,
    required this.level,
    required this.icon,
    required this.iconBlob
  });

  Resource.fromJson(Map<String, dynamic> json) :
    name = json["name"],
    enable = true,
    time = json["time"],
    level = json["level"],
    icon = json["icon"],
    iconBlob = null;
}

/// Production
class Product {
  String name;
  bool enable;
  bool mineable;
  /// Amount for each production
  int amount;
  /// Time (seconds) to produce
  int? produceTime;
  /// Time (seconds) to mine
  int? mineTime;
  int level;
  String? icon;
  Uint8List? iconBlob;

  Product({
    required this.name,
    required this.amount,
    required this.enable,
    required this.mineable,
    required this.produceTime,
    required this.mineTime,
    required this.level,
    required this.icon,
    required this.iconBlob
  });

  Product.fromJson(Map<String, dynamic> json) :
    name = json["name"],
    enable = true,
    mineable = false,
    amount = json["amount"],
    produceTime = json["produceTime"],
    mineTime = json["mineTime"],
    level = json["level"],
    icon = json["icon"],
    iconBlob = null;
}

/// How much of a material is needed to produce a product
class ProductMaterial {
  /// Product to be produced
  String product;
  /// Material needed
  String material;
  /// `true` if material is resource, `false` if material is an other product
  bool isResource;
  /// Amount of material needed
  int amount;

  ProductMaterial({
    required this.product,
    required this.material,
    required this.amount,
    required this.isResource
  });

  ProductMaterial.fromJson(Map<String, dynamic> json) :
    product = json["product"],
    material = json["material"],
    isResource = json["isResource"],
    amount = json["amount"];
}

enum JobType {
  input(rawValue: 0),
  inventory(rawValue: 1);

  final int rawValue;
  const JobType({required this.rawValue});
  factory JobType.init(int value) {
    return values.firstWhere((element) => element.rawValue == value);
  }
}

/// Job to be done
class ProductionJob {
  /// Material to be produced or mined
  String material;
  /// `true` if material is required; `false` if material is in inventory
  JobType type;
  /// `true` if material is resource
  bool isResource;
  /// Required amount
  int amount;

  ProductionJob({
    required this.material,
    required this.type,
    required this.isResource,
    required this.amount
  });
}
