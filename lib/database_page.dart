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


import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:train_station_2_calc/crop_view.dart';
import 'package:train_station_2_calc/database.dart';
import 'package:train_station_2_calc/dialogs.dart';
import 'package:train_station_2_calc/image_crop_page.dart';
import 'package:train_station_2_calc/isolations.dart';
import 'package:train_station_2_calc/main.dart';
import 'package:train_station_2_calc/models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:train_station_2_calc/anti_confuse.dart';
import 'package:image/image.dart';
import 'package:train_station_2_calc/product_page.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<StatefulWidget> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> with RouteAware {

  final _DatabasePageDataController _dataController = _DatabasePageDataController();
  final NumberFormat _numberFormat = NumberFormat("#,###", "en_US");
  bool _shouldReloadData = false;

  @override
  void initState() {
    super.initState();
    _dataController.loadData().then((value) => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (_shouldReloadData) {
      _shouldReloadData = false;
      // _dataController.loadData().then((value) => setState(() {}));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext wgBuildCtx) {
    final List<int> lengths = [
      _dataController.resources.length,
      _dataController.products.length,
      0
    ];
    final int numOfRows = TableIndex.getNumberOrRows(lengths);
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
            child: const Text("Enable\nby level", textAlign: TextAlign.center, style: TextStyle(color: Colors.white),)
          )
        ],
      ),
      body: Column(children: [
        Row(children: [
          const SizedBox(width: 8),
          Expanded(child: TextField(
            autofocus: false,
            decoration: const InputDecoration(labelText: "Filter by name"),
            onChanged: _filterTextOnChange,
          )),
          const SizedBox(width: 8)
        ]),
        Expanded(child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Table(
              border: const TableBorder(horizontalInside: BorderSide(color: Colors.grey, width: 0.5)),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const <int, TableColumnWidth>{
                0: FixedColumnWidth(80),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(40),
                3: FixedColumnWidth(40)
              },
              children: List<TableRow>.generate(numOfRows, (index) {
                final TableIndex tableIndex = TableIndex(index: index, sectionLengths: lengths);
                if (tableIndex.row == null) {
                  return _makeSectionRow(tableIndex.section);
                }
                if (tableIndex.section == 0) {
                  return _makeResourceRow(tableIndex.row!);
                }
                return _makeProductRow(tableIndex.row!);
              }),
            ),
          ],
        ))
      ])
    );
  }

  TableRow _makeSectionRow(int section) {
    if (section == 2) {
      return TableRow(children: screenBottoms(4));
    }
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        SizedBox(
          height: 50,
          child: IconButton(
            onPressed: section == 0 ? _addNewResourceOnTap : _addNewProductOnTap,
            icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
            iconSize: 32
          )
        ),
        Text(
          section == 0 ? "MINERALS" : "PRODUCTS",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
        ),
        section == 0 ?
          Container() :
          const Text("Minable", textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 10)),
        const Text("Enable", textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 10)),
      ]
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
          Checkbox(
            value: resource.enable,
            onChanged: (newvalue) => _resourceEnableOnChange(index, newvalue ?? false)
          )
      ]
    );
  }

  TableRow _makeProductRow(int index) {
    final product = _dataController.products[index];
    String title = product.name;
    if (!(product.isRegionFactoryAvailabe && product.mineable)) {
      title += " (${_numberFormat.format(product.amount)} units / ${DurationComponents.init(product.produceTime ?? 0).formatedString})";
    }
    return TableRow(
      children: [
        IconButton(
          onPressed: () => _iconProductOnTap(index),
          icon: loadIcon(product.icon, product.iconBlob)
        ),
        TextButton(
          onPressed: () => _productRowOnSelection(index),
          style: ButtonStyle(
            padding: MaterialStateProperty.all(EdgeInsets.zero),
            alignment: Alignment.centerLeft,
            foregroundColor: MaterialStateProperty.all(Colors.white),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.normal)),
        ),
        product.isRegionFactoryAvailabe ?
          Checkbox(
            value: product.mineable,
            onChanged: (newValue) => _mineableEnableOnChange(index, newValue ?? false)
          ) :
          Container(),
        product.level == 0 ?
          IconButton(
            onPressed: () => _removeProductOnTap(index),
            icon: const Icon(Icons.delete, color: Colors.red)
          ) :
          Checkbox(
            value: product.enable,
            onChanged: (newValue) => _productEnableOnChange(index, newValue ?? false)
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
    final Product product = _dataController.products[index];
    _shouldReloadData =  true;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductPage(product: product)));
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
          // ignore: use_build_context_synchronously
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
        _productRowOnSelection(0);
      } else if (text.isNotEmpty) {
        showRetry(
          // ignore: use_build_context_synchronously
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
    _showIconSettings(_dataController.resources[index].name, (ImgImage? image) {
      Uint8List? blob;
      if (image != null) {
        blob = encodePng(image);
      }
      _dataController.updateResourceIcon(index, blob).then((value) => setState(() {}));
    });
  }

  void _iconProductOnTap(int index) {
    _showIconSettings(_dataController.products[index].name, (ImgImage? image) {
      showLoading(context);
      compute((image) {
        Uint8List? blob;
        if (image != null) {
          blob = encodePng(image);
        }
        return blob;
      }, image).then((blob) async {
        await _dataController.updateProductIcon(index, blob);
      }).then((value) {
        setState(() {});
        closeLoading();
      });
    });
  }

  List<Widget> _buildIconSettingsButtons(BuildContext dlgCtx, String title, Function(ImgImage?) completion) {
    List<Widget> buttons = [
      const SizedBox(height: 16, width: 300),
      Text("Icon setting for \"$title\"", style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16, width: 300)
    ];
    if (!Platform.isAndroid) {
      buttons.addAll([
        TextButton(
          style: ButtonStyle(
            minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
            backgroundColor: MaterialStateProperty.all(Colors.white)
          ),
          onPressed: () async {
            Navigator.of(dlgCtx).pop();
            _pickPasteboard(completion);
          },
          child: const Text("Pasteboard")
        )
      ]);
    }
    if (isPhone()) {
      buttons.addAll([
        const SizedBox(height: 16, width: 300),
          TextButton(
            style: ButtonStyle(
              minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
              backgroundColor: MaterialStateProperty.all(Colors.white)
            ),
            onPressed: () async {
              Navigator.of(dlgCtx).pop();
              _pickImage(true, completion);
            },
            child: const Text("Camera")
          ),
          const SizedBox(height: 16, width: 300),
          TextButton(
            style: ButtonStyle(
              minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
              backgroundColor: MaterialStateProperty.all(Colors.white)
            ),
            onPressed: () async {
              Navigator.of(dlgCtx).pop();
              _pickImage(false, completion);
            },
            child: const Text("Library")
          )
      ]);
    }
    buttons.addAll([
      const SizedBox(height: 16, width: 300),
      TextButton(
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
          backgroundColor: MaterialStateProperty.all(Colors.white)
        ),
        onPressed: () async {
          Navigator.of(dlgCtx).pop();
          _pickFile(completion);
        },
        child: const Text("File")
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
          launchUrlString(Uri.encodeFull("https://www.google.com/search?q=${title}&udm=2&tbs=isz:i"));
        },
        child: const Text("Google it!")
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
    ]);
    return buttons;
  }

  void _showIconSettings(String title, Function(ImgImage?) completion) {
    showModalBottomSheet(
      context: context,
      builder: (dlgCtx) => Wrap(children: [Column(
        children: _buildIconSettingsButtons(dlgCtx, title, completion)
      )])
    );
  }

  void _pasteboardFailed() {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text("Error"),
        content: const Text("Pasteboard is empty or does not contain image."),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dlgContext).pop();
            }
          )
        ]
      )
    );
  }

  void _pickPasteboard(Function(ImgImage?) completion) async {
    if (!isPhone()) {
      List<String> files = await Pasteboard.files();
      if (files.isNotEmpty) {
        File file = File(files.first);
        showLoading(context);
        Isolations.loadImageFromFile(file).then((value) {
          closeLoading();
          if (value != null) {
            _cropImage(value, completion);
          } else {
            _pasteboardFailed();
          }
        });
      } else {
        _pasteboardFailed();
      }
    } else {
      Uint8List? data = await Pasteboard.image;
      if (data != null) {
        showLoading(context);
        Isolations.loadImageFromData(data).then((value) {
          closeLoading();
          if (value != null) {
            _cropImage(value, completion);
          } else {
            _pasteboardFailed();
          }
        });
      } else {
        _pasteboardFailed();
      }
    }
  }

  void _pickFile(Function(ImgImage?) completion) async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      if ((info.version.sdkInt ?? 0) <= 32) {
        if ((await Permission.storage.isDenied) && !(await Permission.storage.request()).isGranted) {
          return;
        }
      } else {
        bool isDenied = await Permission.photos.isDenied;
        if (isDenied) {
          if (!(await Permission.photos.request()).isGranted) {
            return;
          }
        }
      }
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: isPhone() ? FileType.any : FileType.image, withData: true);
    Uint8List? data = result?.files.first.bytes;
    if (data != null) {
      showLoading(context);
      Isolations.loadImageFromData(data).then((value) {
        closeLoading();
        if (value != null) {
          _cropImage(value, completion);
        }
      });
    }
  }

  void _pickImage(bool isCamera, Function(ImgImage?) completion) async {
    final ImagePicker picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery);
    } catch (error) {
      showRetry(
        // ignore: use_build_context_synchronously
        context,
        "Something wrong",
        "Fail to load given image. Please select a differenct one.",
        () => _pickImage(isCamera, completion)
      );
      return;
    }
    if (file != null && context.mounted) {
      // ignore: use_build_context_synchronously
      showLoading(context);
      Isolations.loadImageFromXFile(file).then((value) {
        closeLoading();
        if (value != null) {
          _cropImage(value, completion);
        }
      });
    }
  }

  void _cropImage(ImgImage image, Function(ImgImage?) completion) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ImageCropPage(
      image: image,
      onCompletion:(angle, rect) {
        showLoading(context);
        Isolations.cropResizeImage(image, angle, rect).then((value) {
          closeLoading();
          completion(value);
        });
      }
    )));
  }

  void _filterTextOnChange(String value) {
    _dataController.filter = value.trim().toLowerCase();
    setState(() {
      _dataController.doFilter();
    });
  }

}

class _DatabasePageDataController {

  List<Resource> resources = [];
  List<Product> products = [];
  List<Resource> _allResources = [];
  List<Product> _allProducts = [];
  String filter = "";

  Future<void> loadData() async {
    final db = MaterialDatabase();
    _allResources = await db.loadAllResources();
    _allProducts = await db.loadAllProducts();
    doFilter();
  }

  void doFilter() {
    resources.clear();
    products.clear();
    if (filter.isEmpty) {
      resources.addAll(_allResources);
      products.addAll(_allProducts);
    } else {
      for (Resource resource in _allResources) {
        if (resource.name.contains(filter)) {
          resources.add(resource);
        }
      }
      for (Product product in _allProducts) {
        if (product.name.contains(filter)) {
          products.add(product);
        }
      }
    }
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
    await MaterialDatabase().enableByLevel(level);
    await loadData();
  }

  Future<void> _enableByLevel(int level) async {
    for (Resource resource in resources) {
      resource.enable = resource.level <= level;
    }
    await MaterialDatabase().updateResources(resources);

    for (Product product in products) {
      product.enable = product.level <= level;
      if (product.isRegionFactoryAvailabe && product.level > 0) {
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
    if (!(await db.deleteProductMaterials(product.name))) {
      return false;
    }
    products.removeAt(index);
    return true;
  }

}