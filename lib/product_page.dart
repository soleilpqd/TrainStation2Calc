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

class _ProductPageState extends State<ProductPage> {

  final _ProductPageDataController _dataController = _ProductPageDataController();
  final NumberFormat _numberFormat = NumberFormat("#,###", "en_US");

  @override
  void initState() {
    super.initState();
    _dataController.loadData(widget.product.name).then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext wgBuildCtx) {
    final int numOfRows = _dataController.materials.length;
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
        )
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          height: 50,
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: IconButton(
                  icon: Icon(Icons.add_circle, color: Theme.of(wgBuildCtx).colorScheme.primary),
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
            ]
          )
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Table(
              border: const TableBorder(horizontalInside: BorderSide(color: Colors.grey, width: 0.5)),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const <int, TableColumnWidth>{
                0: FixedColumnWidth(80),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(60),
                3: FixedColumnWidth(40),
              },
              children: List<TableRow>.generate(numOfRows, (index) {
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
                return TableRow(children: [
                  IconButton(
                    onPressed: () => _amoutOnTap(index),
                    icon: loadIcon(icon, iconBlob),
                    style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.transparent)),
                  ),
                  TextButton(
                    onPressed: () => _amoutOnTap(index),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                      alignment: Alignment.centerLeft,
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      overlayColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                    child: Text(material.material, style: const TextStyle(fontWeight: FontWeight.normal)),
                  ),
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
                ]);
              }),
            ),
          ],
        ))
      ])
    );
  }

  void _addMaterialOnTap() {
    // TODO: exclude to avoid cycle
    List<String> resourceNames = [];
    List<String> productNames = [widget.product.name];
    for (ProductMaterial material in _dataController.materials) {
      if (material.isResource) {
        resourceNames.add(material.material);
      } else {
        productNames.add(material.material);
      }
    }
    showDialog(
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

}

class _ProductPageDataController {

  List<ProductMaterial> materials = [];
  Map<String, Resource> resourceCache = {};
  Map<String, Product> productCache = {};
  String _productName = "";

  Future<void> loadData(String productName) async {
    _productName = productName;
    MaterialDatabase db = MaterialDatabase();
    materials = await db.loadMaterialsForProducts([productName]);
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

  Future<void> addNewMaterial(String name, bool isResource) async {
    final MaterialDatabase db = MaterialDatabase();
    final ProductMaterial newMaterial = ProductMaterial(
      product: _productName,
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

}