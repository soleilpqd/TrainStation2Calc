/*
  Train Station 2 Calculator - Simple resource calculator to play TrainStation2
  Copyright (C) <year>  <name of author>

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
import 'package:flutter/material.dart';
import 'package:train_station_2_calc/database.dart';
import 'package:train_station_2_calc/dialogs.dart';
import 'package:train_station_2_calc/models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<StatefulWidget> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {

  final _DatabasePageDataController _dataController = _DatabasePageDataController();

  @override
  void initState() {
    super.initState();
    _dataController.loadData().then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext wgBuildCtx) {
    final numOfRows = (_dataController.resources.isEmpty ? 0 : _dataController.resources.length + 1) + (_dataController.products.isEmpty ? 0 : _dataController.products.length + 1);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(wgBuildCtx).colorScheme.primary,
        title: const Text("Database"),
        actions: [
          TextButton(
            onPressed: _resetDBOnTap,
            child: const Text("Reset", style: TextStyle(color: Colors.white),)
          ),
          TextButton(
            onPressed: _enableByLevelOnTap,
            child: const Text("Enable by level", style: TextStyle(color: Colors.white),)
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Table(
            border: const TableBorder(horizontalInside: BorderSide(color: Colors.grey, width: 0.5)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(80),
              1: FlexColumnWidth(),
              2: FixedColumnWidth(64),
              3: FixedColumnWidth(50)
            },
            children: List<TableRow>.generate(numOfRows, (index) {
              if (index == 0) {
                return TableRow(
                  decoration: const BoxDecoration(color: Colors.white),
                  children: [
                    IconButton(
                      onPressed: _dataController.resources.isNotEmpty ? _addNewResourceOnTap : _addNewProductOnTap,
                      icon: Icon(Icons.add_circle, color: Theme.of(wgBuildCtx).colorScheme.primary)
                    ),
                    Text(
                      _dataController.resources.isNotEmpty ? "MINERALS" : "PRODUCTS",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                    ),
                    Container(height: 50),
                    const Text("Enable", style: TextStyle(color: Colors.black)),
                  ]
                );
              }
              if (_dataController.resources.isNotEmpty) {
                if (index == _dataController.resources.length + 1) {
                  return TableRow(
                    decoration: const BoxDecoration(color: Colors.white),
                    children: [
                      IconButton(
                        onPressed: _addNewProductOnTap,
                        icon: Icon(Icons.add_circle, color: Theme.of(wgBuildCtx).colorScheme.primary)
                      ),
                      const Text("PRODUCTS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      const Text("Minable", style: TextStyle(color: Colors.black)),
                      const Text("Enable", style: TextStyle(color: Colors.black))
                    ]
                  );
                }
                if (index <= _dataController.resources.length) {
                  return _makeResourceRow(index - 1);
                }
                return _makeProductRow(index - _dataController.resources.length - 2);
              }
              return _makeProductRow(index - 1);
            }),
          ),
        ],
      )
    );
  }

  TableRow _makeResourceRow(int index) {
    final resource = _dataController.resources[index];
    return TableRow(
      children: [
        IconButton(
          onPressed: () => _iconResourceOnTap(index),
          icon: loadIcon(resource.icon, resource.iconBlob)
        ),
        Text(resource.name, textAlign: TextAlign.left, style: const TextStyle(color: Colors.white)),
        Container(),
        resource.level == 0 ?
          IconButton(
            onPressed: () => _removeResourceOnTap(index),
            icon: const Icon(Icons.delete, color: Colors.red)
          ) :
          Switch(
            value: resource.enable,
            onChanged: (bool newValue) => _resourceEnableOnChange(index, newValue)
          )
      ]
    );
  }

  TableRow _makeProductRow(int index) {
    final product = _dataController.products[index];
    return TableRow(
      children: [
        IconButton(
          onPressed: () => _iconProductOnTap(index),
          icon: loadIcon(product.icon, product.iconBlob)
        ),
        TextButton(
          onPressed: () => _productRowOnSelection(index),
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            foregroundColor: MaterialStateProperty.all(Colors.white),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
          child: Text(product.name),
        ),
        product.mineTime != null && product.mineTime! > 0 ?
          Switch(
            value: product.mineable,
            onChanged: (bool newValue) => _mineableEnableOnChange(index, newValue)
          ) :
          Container(),
        product.level == 0 ?
          IconButton(
            onPressed: () => _removeProductOnTap(index),
            icon: const Icon(Icons.delete, color: Colors.red)
          ) :
          Switch(
            value: product.enable,
            onChanged: (bool newValue) => _productEnableOnChange(index, newValue)
          )
      ]
    );
  }

  void _resetDBOnTap() {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text("Reset"),
        content: const Text("This deletes all manual data, including your current calculations,\nand resets data to default values."),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dlgContext).pop()
          ),
          TextButton(
            child: const Text('Reset'),
            onPressed: () {
              Navigator.of(dlgContext).pop();
              MaterialDatabase().resetDatabase().then((value) => _dataController.loadData().then((value) => setState(() {})));
            },
          ),
        ],
      )
    );
  }

  void _enableByLevelOnTap() {
    inputNumberDialogBuilder(context, "Input your level", "", (value) {
      _dataController.enableByLevel(int.parse(value)).then((value) => setState(() {}));
    });
  }

  void _productRowOnSelection(int index) {

  }

  void _resourceEnableOnChange(int index, bool value) {
    _dataController.updateResourceEnable(index, value).then((value) => setState(() {}));
  }

  void _productEnableOnChange(int index, value) {
    _dataController.updateProductEnable(index, value).then((value) => setState(() {}));
  }

  void _mineableEnableOnChange(int index, bool value) {
    _dataController.updateProductMinable(index, value).then((value) => setState(() {}));
  }

  void _addNewItem(String title, Function(String) completion, {String name = ""}) {
    TextEditingController controller = TextEditingController(text: name);
    showDialog<void>(
      context: context,
      builder: (dlgCtx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
              autofocus: true,
              controller: controller
            ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dlgCtx).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                Navigator.of(dlgCtx).pop();
                completion(controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  void _addNewResourceOnTap({String name = ""}) {
    _addNewItem("Input mineral name", name: name, (text) async {
      if (await _dataController.addNewResource(text)) {
        setState(() {});
      } else if (text.isNotEmpty) {
        showRetry(
          context,
          "Fail to create mineral with name '$text'",
          "Please input a different name",
          () => _addNewResourceOnTap(name: text)
        );
      }
    });
  }

  void _removeResourceOnTap(int index) {
    _dataController.removeResource(index).then((result) {
      if (result) {
        setState(() {});
      }
    });
  }

  void _addNewProductOnTap({String name = ""}) {
    _addNewItem("Input product name", name: name, (text) async {
      if (await _dataController.addNewProduct(text)) {
        setState(() {});
      } else if (text.isNotEmpty) {
        showRetry(
          context,
          "Fail to create product with name '$text'",
          "Please input a different name",
          () => _addNewProductOnTap(name: text)
        );
      }
    });
  }

  void _removeProductOnTap(int index) {
    _dataController.removeProduct(index).then((result) {
      if (result) {
        setState(() {});
      }
    });
  }

  void _iconResourceOnTap(int index) {
    _showIconSettings(_dataController.resources[index].name, (image) {
      Uint8List? blob;
      if (image != null) {
        blob = img.encodeJpg(image);
      }
      _dataController.updateResourceIcon(index, blob).then((value) => setState(() {}));
    });
  }

  void _iconProductOnTap(int index) {
    _showIconSettings(_dataController.products[index].name, (image) {
      Uint8List? blob;
      if (image != null) {
        blob = img.encodeJpg(image);
      }
      _dataController.updateProductIcon(index, blob).then((value) => setState(() {}));
    });
  }

  void _showIconSettings(String title, Function(img.Image?) completion) {
    showModalBottomSheet(
      context: context,
      builder: (dlgCtx) => Wrap(children: [Column(
        children: [
          const SizedBox(height: 16, width: 300),
          Text("Icon setting for \"$title\"", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16, width: 300),
          TextButton(
            style: ButtonStyle(
              minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
              backgroundColor: MaterialStateProperty.all(Colors.white)
            ),
            onPressed: () async {
              Navigator.of(dlgCtx).pop();
              _pickImage(completion);
            },
            child: const Text("Pick from file")
          ),
          const SizedBox(height: 16, width: 300),
          TextButton(
            style: ButtonStyle(
              minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
              backgroundColor: MaterialStateProperty.all(Colors.white)
            ),
            onPressed: () {
              Navigator.of(dlgCtx).pop();
              completion(null);
            },
            child: const Text("Default", style: TextStyle(color: Colors.red))
          ),
          const SizedBox(height: 16, width: 300),
          TextButton(
            style: ButtonStyle(
              minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
              backgroundColor: MaterialStateProperty.all(Colors.white)
            ),
            onPressed: () {
              Navigator.of(dlgCtx).pop();
            },
            child: const Text("Cancel")
          ),
          const SizedBox(height: 50, width: 300)
        ]
      )])
    );
  }

  void _pickImage(Function(img.Image?) completion) async {
    final ImagePicker picker = ImagePicker();
    try {
      XFile? file = await picker.pickImage(source: ImageSource.gallery, maxHeight: 50.0);
      if (file != null) {
        Uint8List data = await file.readAsBytes();
        final cmd = img.Command()
          ..decodeImage(data)
          ..copyResize(height: 50);
        await cmd.executeThread();
        completion(cmd.outputImage);
      }
    } on Exception {
      showRetry(
        context,
        "Something wrong",
        "Fail to load given image. Please select a differenct one.",
        () => _pickImage(completion)
      );
    }
  }

}

class _DatabasePageDataController {

  List<Resource> resources = [];
  List<Product> products = [];

  Future<void> loadData() async {
    final db = MaterialDatabase();
    resources = await db.loadAllResources();
    products = await db.loadAllProducts();
  }

  /// Return list of product names which require input product [name] to produce
  Future<List<String>> _getProductsDependOnProduct(String name) async {
    MaterialDatabase db = MaterialDatabase();
    List<ProductMaterial> materials = await db.loadMaterialsForResources([name], false);
    return materials.map((element) => element.product).toList();
  }

  /// Starting from given product [names] list,
  /// find recursive products names which require products in [names] list to produce
  Future<List<String>> _getDownwardRelatedProducts(List<String> names) async {
    List<String> queue = names;
    List<String> result = [];
    while (queue.isNotEmpty) {
      String name = queue.removeAt(0);
      if (!result.contains(name)) {
        result.add(name);
        List<String> relatedProducts = await _getProductsDependOnProduct(name);
        for (String rName in relatedProducts) {
          if (!queue.contains(rName) && !result.contains(rName)) {
            queue.add(rName);
          }
        }
      }
    }
    return result;
  }

  List<Resource> _fillResources(List<String> names) {
    List<Resource> result = [];
    for (Resource resource in resources) {
      for (String name in names) {
        if (name == resource.name) {
          result.add(resource);
          break;
        }
      }
    }
    return result;
  }

  List<Product> _fillProducts(List<String> names) {
    List<Product> result = [];
    for (Product product in products) {
      for (String name in names) {
        if (name == product.name) {
          result.add(product);
          break;
        }
      }
    }
    return result;
  }

  /// Find recursive resources and products which are required to produce products in [queueProductNames] list
  Future<void> _getUpwardRelatedMaterials(
    List<String> queueProductNames,
    List<String> resResourceNames,
    List<String> resProductNames) async {
      String prodName = queueProductNames.removeAt(0);
      if (!resProductNames.contains(prodName)) {
        resProductNames.add(prodName);
        List<ProductMaterial> materials = await MaterialDatabase().loadMaterialsForProducts([prodName]);
        for (ProductMaterial material in materials) {
          if (material.isResource) {
            if (!resResourceNames.contains(material.material)) {
              resResourceNames.add(material.material);
            }
          } else {
            if (!resProductNames.contains(material.material) && !queueProductNames.contains(material.material)) {
              queueProductNames.add(material.material);
            }
          }
        }
      }
  }

  /// Update `enable` property of resource at [index] to [value].
  /// If resource is disable, disable recursive products which require the resource to produce.
  Future<void> updateResourceEnable(int index, bool value) async {
    final Resource resource = resources[index];
    resource.enable = value;
    MaterialDatabase db = MaterialDatabase();
    await db.updateResource(resource);
    if (!value) {
      List<ProductMaterial> materials = await db.loadMaterialsForResources([resource.name], true);
      List<String> productsToDisable = await _getDownwardRelatedProducts(materials.map((element) => element.product).toList());
      List<Product> materialProducts = _fillProducts(productsToDisable);
      if (materialProducts.isNotEmpty) {
        for (Product product in materialProducts) {
          product.enable = false;
        }
        await db.updateProducts(materialProducts);
      }
    }
  }

  /// Update `enable` property of product at [index] to [value].
  /// If product is enable, enable recursive resources and products which are required to produce the product.
  /// If product is disable, disable recursive products which require the product to produce.
  Future<void> updateProductEnable(int index, bool value) async {
    final Product product = products[index];
    product.enable = value;
    MaterialDatabase db = MaterialDatabase();
    await db.updateProduct(product);
    if (value) {
      List<String> queue = [product.name];
      List<String> resourcesToEnable = [];
      List<String> productsToEnable = [];
      while (queue.isNotEmpty) {
        await _getUpwardRelatedMaterials(queue, resourcesToEnable, productsToEnable);
      }
      List<Resource> ress = _fillResources(resourcesToEnable);
      List<Product> prods = _fillProducts(productsToEnable);
      if (ress.isNotEmpty) {
        for (Resource res in ress) {
          res.enable = true;
        }
        await db.updateResources(ress);
      }
      if (prods.isNotEmpty) {
        for (Product prod in prods) {
          prod.enable = true;
        }
        await db.updateProducts(prods);
      }
    } else {
      List<String> productsToDisable = await _getDownwardRelatedProducts([product.name]);
      List<Product> materialProducts = _fillProducts(productsToDisable);
      if (materialProducts.isNotEmpty) {
        for (Product prod in materialProducts) {
          prod.enable = false;
        }
        await db.updateProducts(materialProducts);
      }
    }
  }

  Future<void> updateProductMinable(int index, bool value) async {
    final Product product = products[index];
    product.mineable = value;
    MaterialDatabase db = MaterialDatabase();
    await db.updateProduct(product);
  }

  Future<void> updateResourceIcon(int index, Uint8List? value) async {
    final Resource resource = resources[index];
    resource.iconBlob = value;
    MaterialDatabase db = MaterialDatabase();
    await db.updateResource(resource);
  }

  Future<void> updateProductIcon(int index, Uint8List? value) async {
    final Product product = products[index];
    product.iconBlob = value;
    MaterialDatabase db = MaterialDatabase();
    await db.updateProduct(product);
  }

  Future<void> enableByLevel(int level) async {
    for (Resource resource in resources) {
      resource.enable = resource.level <= level;
    }
    await MaterialDatabase().updateResources(resources);

    for (Product product in products) {
      product.enable = product.level <= level;
      if (product.mineTime != null) {
        product.mineable = product.enable;
      }
    }
    await MaterialDatabase().updateProducts(products);
  }

  Future<bool> addNewResource(String name) async {
    final MaterialDatabase db = MaterialDatabase();
    String newName = name.trim().toLowerCase();
    if (newName.isEmpty) {
      return false;
    }
    List<Resource> list = await db.loadEnableResources(included: [newName], enable: false);
    if (list.isNotEmpty) {
      return false;
    }
    final Resource newResource = Resource(name: name, enable: true, time: 0, level: 0, icon: null, iconBlob: null);
    if (!(await db.insertResource(newResource))) {
      return false;
    }
    resources.insert(0, newResource);
    return true;
  }

  Future<bool> removeResource(int index) async {
    final MaterialDatabase db = MaterialDatabase();
    final resource = resources[index];
    if (resource.level > 0) {
      return false;
    }
    if (!(await db.deleteResource(resource.name))) {
      return false;
    }
    resources.removeAt(index);
    return true;
  }

Future<bool> addNewProduct(String name) async {
    final MaterialDatabase db = MaterialDatabase();
    String newName = name.trim().toLowerCase();
    if (newName.isEmpty) {
      return false;
    }
    List<Product> list = await db.loadEnableProducts(included: [newName], enable: false);
    if (list.isNotEmpty) {
      return false;
    }
    final Product newProduct = Product(
      name: name,
      amount: 0,
      enable: true,
      mineable: false,
      produceTime: null,
      mineTime: null,
      level: 0,
      icon: null,
      iconBlob: null
    );
    if (!(await db.insertProduct(newProduct))) {
      return false;
    }
    products.insert(0, newProduct);
    return true;
  }

  Future<bool> removeProduct(int index) async {
    final MaterialDatabase db = MaterialDatabase();
    final Product product = products[index];
    if (product.level > 0) {
      return false;
    }
    if (!(await db.deleteProduct(product.name))) {
      return false;
    }
    products.removeAt(index);
    return true;
  }

}