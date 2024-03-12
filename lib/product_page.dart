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

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';
import 'package:train_station_2_calc/data_selection_page.dart';
import 'package:train_station_2_calc/database.dart';
import 'package:train_station_2_calc/dialogs.dart';
import 'package:train_station_2_calc/models.dart';

class ProductPage extends StatefulWidget {

  final Product product;

  const ProductPage({super.key, required this.product});

  @override
  State<StatefulWidget> createState() => _ProductPageState();

}

enum _FirstSectionRow {
  enability,
  regionFactory,
  mineable,
  quantity,
  duration
}

class _ProductPageState extends State<ProductPage> {

  final _ProductPageDataController _dataController = _ProductPageDataController();
  final NumberFormat _numberFormat = NumberFormat("#,###", "en_US");

  @override
  void initState() {
    super.initState();
    _dataController.loadData(widget.product).then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext wgBuildCtx) {
    List<_FirstSectionRow> firstSectionRows = [];
    if (widget.product.level > 0) {
      firstSectionRows.add(_FirstSectionRow.enability);
    }
    firstSectionRows.add(_FirstSectionRow.regionFactory);
    if (widget.product.isRegionFactoryAvailabe) {
      firstSectionRows.add(_FirstSectionRow.mineable);
      if (!widget.product.mineable) {
        firstSectionRows.add(_FirstSectionRow.quantity);
        firstSectionRows.add(_FirstSectionRow.duration);
      }
    } else {
      firstSectionRows.add(_FirstSectionRow.quantity);
      firstSectionRows.add(_FirstSectionRow.duration);
    }
    List<int> lengths = [firstSectionRows.length, _dataController.materials.length];
    final int numOfRows = TableIndex.getNumberOrRows(lengths);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(wgBuildCtx).colorScheme.primary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loadIcon(widget.product.icon, widget.product.iconBlob),
            const SizedBox(width: 10),
            Text(widget.product.name.toUpperCase())
          ]
        ),
      ),
      body: ListView(
        children: [
          Table(
            border: const TableBorder(horizontalInside: BorderSide(color: Colors.grey, width: 0.5)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth()
            },
            children: List<TableRow>.generate(numOfRows, (index) {
              final TableIndex tableIndex = TableIndex(index: index, sectionLengths: lengths);
              if (tableIndex.row == null) {
                return _makeSectionHeader(tableIndex.section);
              }
              if (tableIndex.section == 0) {
                return _makeInfoCell(tableIndex.row!, firstSectionRows);
              }
              return _makeMaterialCell(tableIndex.row!);
            }),
          ),
        ],
      )
    );
  }

  TableRow _makeSectionHeader(int section) {
    List<Widget> content = [];
    if (section == 0) {
      content = [
        const SizedBox(width: 8, height: 48),
        const Text("GENERAL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
      ];
    } else {
      content = [
        SizedBox(
          width: 50,
          child: IconButton(
            icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
            iconSize: 32,
            onPressed: _addMaterialOnTap,
          ),
        ),
        const Text("MATERIALS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        Expanded(child: Container()),
        const SizedBox(
          width: 40,
          child: Text("Amount", textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 10)),
        ),
        Container(width: 60)
      ];
    }
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [Row(children: content)]
    );
  }

  TableRow _makeInfoCell(int index, List<_FirstSectionRow> rows) {
    String title = "";
    late Widget content;
    switch (rows[index]) {
      case _FirstSectionRow.enability:
        title = "Enable";
        content = Checkbox(value: widget.product.enable, onChanged: _enableOnChange);
      case _FirstSectionRow.regionFactory:
        title = "Region factory available";
        content = Checkbox(value: widget.product.isRegionFactoryAvailabe, onChanged: _regionFactoryOnChange);
      case _FirstSectionRow.mineable:
        title = "Region factory unlocked";
        content = Checkbox(value: widget.product.mineable, onChanged: _mineableOnChange);
      case _FirstSectionRow.quantity:
        title = "Production quantity";
        content = TextButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(Colors.white),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        onPressed: _productionAmoutOnTap,
        child: Text(_numberFormat.format(widget.product.amount))
      );
      case _FirstSectionRow.duration:
        title = "Production duration";
        content = TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.white),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
          onPressed: _productionDurationOnTap,
          child: Text(DurationComponents.init(widget.product.produceTime ?? 0).formatedString)
        );
    }
    return TableRow(children: [Row(children: [
      Expanded(child: Text(title, textAlign: TextAlign.right)),
      const SizedBox(width: 8),
      SizedBox(width: 120, child: content)
    ])]);
  }

  TableRow _makeMaterialCell(int index) {
    final ProductMaterial material = _dataController.materials[index];
    String? icon;
    Uint8List? iconBlob;
    if (material.isResource) {
      final Resource resource = _dataController.resourceCache[material.material]!;
      icon = resource.icon;
      iconBlob = resource.iconBlob;
    } else {
      final Product product = _dataController.productCache[material.material]!;
      icon = product.icon;
      iconBlob = product.iconBlob;
    }
    return TableRow(children: [Row(children: [
      IconButton(
        onPressed: () => _amoutOnTap(index),
        icon: loadIcon(icon, iconBlob),
        style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.transparent)),
      ),
      Expanded(child: TextButton(
        onPressed: () => _amoutOnTap(index),
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          alignment: Alignment.centerLeft,
          foregroundColor: MaterialStateProperty.all(Colors.white),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        child: Text(material.material, style: const TextStyle(fontWeight: FontWeight.normal)),
      )),
      TextButton(
        onPressed: () => _amoutOnTap(index),
        style: ButtonStyle(
          alignment: Alignment.center,
          foregroundColor: MaterialStateProperty.all(Colors.white),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        child: Text(_numberFormat.format(material.amount), style: const TextStyle(fontWeight: FontWeight.normal)),
      ),
      IconButton(
        onPressed: () => _removeItemOnTap(index),
        icon: const Icon(Icons.delete, color: Colors.red)
      )
    ])]);
  }

  void _addMaterialOnTap() async {
    List<String> resourceNames = [];
    List<String> productNames = [];
    await _dataController.buildExcludedList(resourceNames, productNames);
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => DataSelectionPage(
        excludedResources: resourceNames,
        excludedProducts: productNames,
        isEnableOnly: false,
        completion: (Resource? resource, Product? product) async {
          String name = "";
          bool isResource = false;
          if (resource != null) {
            name = resource.name;
            isResource = true;
          }
          if (product != null) {
            name = product.name;
            isResource = false;
          }
          if (name.isNotEmpty) {
            await _dataController.addNewMaterial(name, isResource);
            _editAmout(_dataController.materials.length - 1);
          }
        })
    );
  }

  void _removeItemOnTap(int index) {
    _dataController.removeMaterial(index).then((value) => setState(() {}));
  }

  void _amoutOnTap(int index) {
    _editAmout(index);
  }

  void _editAmout(int index) {
    final ProductMaterial material = _dataController.materials[index];
    inputNumberDialogBuilder(
      context,
      "Amount of '${material.material}' for each production of '${material.product}'",
      "${material.amount}",
      (value) {
        _dataController.updateMaterialAmount(index, int.parse(value))
          .then((value) => setState(() {}));
      }
    );
  }

  void _enableOnChange(bool? value) {
    widget.product.enable = value ?? false;
    _dataController.saveProduct().then((value) => setState(() {}));
  }

  void _regionFactoryOnChange(bool? value) {
    widget.product.isRegionFactoryAvailabe = value ?? false;
    _dataController.saveProduct().then((value) => setState(() {}));
  }

  void _mineableOnChange(bool? value) {
    widget.product.mineable = value ?? false;
    _dataController.saveProduct().then((value) => setState(() {}));
  }

  void _productionAmoutOnTap() {
    inputNumberDialogBuilder(
      context,
      "Amount of '${widget.product.name}' per each production",
      "${widget.product.amount}",
      (value) {
        widget.product.amount = int.parse(value);
        _dataController.saveProduct().then((value) => setState(() {}));
      }
    );
  }

  void _productionDurationOnTap() {
    List<PickerItem> hours = [];
    for (int index = 0; index < 3; index += 1) {
      hours.add(PickerItem(text: Text("${index}h")));
    }
    List<PickerItem> minutes = [];
    for (int index = 0; index < 59; index += 1) {
      minutes.add(PickerItem(text: Text("${index}m")));
    }
    List<PickerItem> seconds = [];
    for (int index = 0; index < 59; index += 1) {
      seconds.add(PickerItem(text: Text("${index}s")));
    }
    final Picker picker = Picker(
      title: const Text("Production duration"),
      backgroundColor: Colors.black,
      adapter: PickerDataAdapter(
        isArray: true,
        data: [
        PickerItem(children: hours),
        PickerItem(children: minutes),
        PickerItem(children: seconds),
      ]),
      onConfirm: (_, selected) {
        widget.product.produceTime = DurationComponents.fromList(selected).duration;
        _dataController.saveProduct().then((value) => setState(() {}));
      },
    );
    picker.selecteds = DurationComponents.init(widget.product.produceTime ?? 0).toList;
    picker.showModal(context);
  }

}

class _ProductPageDataController {

  List<ProductMaterial> materials = [];
  Map<String, Resource> resourceCache = {};
  Map<String, Product> productCache = {};
  Product? _product;

  Future<void> loadData(Product product) async {
    _product = product;
    MaterialDatabase db = MaterialDatabase();
    materials = await db.loadMaterialsForProducts([product.name]);
    List<String> resourceNames = [];
    List<String> productNames = [];
    for (ProductMaterial material in materials) {
      if (material.isResource) {
        resourceNames.add(material.material);
      } else {
        productNames.add(material.material);
      }
    }

    resourceCache.clear();
    productCache.clear();
    if (resourceNames.isNotEmpty) {
      List<Resource> resources = await db.loadEnableResources(included: resourceNames, enable: false);
      for (Resource resource in resources) {
        resourceCache[resource.name] = resource;
      }
    }
    if (productNames.isNotEmpty) {
      List<Product> products = await db.loadEnableProducts(included: productNames, enable: false);
      for (Product product in products) {
        productCache[product.name] = product;
      }
    }
  }

  Future<void> buildExcludedList(List<String> resourceNames, List<String> productNames) async {
    productNames.add(_product?.name ?? "");
    for (ProductMaterial material in materials) {
      if (material.isResource) {
        resourceNames.add(material.material);
      } else {
        productNames.add(material.material);
      }
    }
    List<ProductMaterial> dependencies = await MaterialDatabase().loadMaterialsForResources([_product?.name ?? ""], null);
    for (ProductMaterial material in dependencies) {
      if (!material.isResource && !productNames.contains(material.product)) {
        productNames.add(material.product);
      }
    }
  }

  Future<void> addNewMaterial(String name, bool isResource) async {
    final MaterialDatabase db = MaterialDatabase();
    final ProductMaterial newMaterial = ProductMaterial(
      product: _product?.name ?? "",
      material: name,
      amount: 0,
      isResource: isResource
    );
    await db.insertMaterial(newMaterial);
    materials.add(newMaterial);
    if (isResource && !resourceCache.containsKey(name)) {
      List<Resource> resources = await db.loadEnableResources(included: [name], enable: false);
      for (Resource resource in resources) {
        resourceCache[resource.name] = resource;
      }
    }
    if (!isResource && !productCache.containsKey(name)) {
      List<Product> products = await db.loadEnableProducts(included: [name], enable: false);
      for (Product product in products) {
        productCache[product.name] = product;
      }
    }
  }

  Future<void> updateMaterialAmount(int index, int value) async {
    final ProductMaterial material = materials[index];
    material.amount = value;
    await MaterialDatabase().updateMaterial(material);
  }

  Future<void> removeMaterial(int index) async {
    await MaterialDatabase().delteMaterial(materials[index]);
    materials.removeAt(index);
  }

  Future<void> saveProduct() async {
    await MaterialDatabase().updateProduct(_product!);
  }

}