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
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:train_station_2_calc/data_history.dart';
import 'package:train_station_2_calc/database.dart';
import 'package:train_station_2_calc/database_page.dart';
import 'package:train_station_2_calc/data_selection_page.dart';
import 'package:train_station_2_calc/dialogs.dart';
import 'package:train_station_2_calc/help_page.dart';
import 'package:train_station_2_calc/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  if (Platform.isLinux) {
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Train Station 2 Calculator",
      home: const MyHomePage(title: "Train Station 2 Calculator"),
      theme: ThemeData.from(colorScheme: const ColorScheme.dark(primary: Colors.blue)),
      navigatorObservers: [routeObserver],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum _HomePageSection {
  input(rawValue: 0),
  inventory(rawValue: 1),
  result(rawValue: 2),
  summary(rawValue: 3),
  bottomSpace(rawValue: 4);

  final int rawValue;

  const _HomePageSection({required this.rawValue});

  factory _HomePageSection.init(int value) {
    return values.firstWhere((element) => element.rawValue == value);
  }
}

class _MyHomePageState extends State<MyHomePage> with RouteAware {

  bool _shouldReloadData = false;
  final _MyHomePageDataController _dataController = _MyHomePageDataController();
  final NumberFormat _numberFormat = NumberFormat("#,###", "en_US");
  List<_HomePageSection> _foldedSections = [];

  @override
  void initState() {
    super.initState();
    _initDB();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  void _initDB() async {
    final db = MaterialDatabase();
    await db.open();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
    MaterialDatabase().close();
  }

  @override
  void didPush() {
    super.didPush();
    _loadData();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (_shouldReloadData) {
      _shouldReloadData = false;
      _loadData();
    }
  }

  void _loadData() {
    if (!MaterialDatabase().isOpen) return;
    _dataController.loadData().then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext wgBuildCtx) {
    List<int> lengths = [
      _foldedSections.contains(_HomePageSection.input) ? 0 : _dataController.items[_HomePageSection.input.rawValue].length,
      _foldedSections.contains(_HomePageSection.inventory) ? 0 : _dataController.items[_HomePageSection.inventory.rawValue].length,
      _dataController.items[_HomePageSection.result.rawValue].length,
      _dataController.items[_HomePageSection.result.rawValue].isNotEmpty ? 4 : 0,
      0
    ];
    final int numOfRows = TableIndex.getNumberOrRows(lengths);
    if (!MaterialDatabase().isOpen) {
      return Container(
        color: Theme.of(wgBuildCtx).colorScheme.primary,
        child: const Center(
          child: Text(
            "Train Station 2 Calculator",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, decoration: TextDecoration.none)
          )),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(wgBuildCtx).colorScheme.primary,
        title: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(widget.title),
        ),
        actions: [
          IconButton(
            onPressed: _allFold,
            icon: const Icon(Icons.expand)
          ),
          IconButton(
            onPressed: _allClear,
            icon: const Icon(Icons.refresh, color: Colors.red)
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              _shouldReloadData = true;
              Navigator.push(wgBuildCtx, MaterialPageRoute(builder: (_) => const DatabasePage()));
            }
          ),
          IconButton(
            onPressed: _helpOnTap,
            icon: const Icon(Icons.help_outline)
          ),
        ],
      ),
      body: ListView(
        children: [
          Table(
            border: const TableBorder(horizontalInside: BorderSide(color: Colors.grey, width: 0.5)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(80),
              1: FlexColumnWidth(),
              2: FixedColumnWidth(100),
              3: FixedColumnWidth(40),
            },
            children: List<TableRow>.generate(numOfRows, (index) {
              final TableIndex tableIndex = TableIndex(index: index, sectionLengths: lengths);
              _HomePageSection section = _HomePageSection.init(tableIndex.section);
              if (section == _HomePageSection.bottomSpace) {
                return TableRow(children: screenBottoms(4));
              }
              if (section == _HomePageSection.summary && _dataController.items[_HomePageSection.result.rawValue].isEmpty) {
                return TableRow(children: [Container(), Container(), Container(), Container()]);
              }
              if (tableIndex.row == null) {
                return _makeSectionHeader(section);
              }
              if (section == _HomePageSection.summary) {
                return _makeSummaryRow(tableIndex.row!);
              }
              return _makeRow(section, tableIndex.row!);
            }),
          ),
        ],
      )
    );
  }

  TableRow _makeSectionHeader(_HomePageSection section) {
    final List<String> titles = [
      "INPUT",
      "INVENTORY",
      "RESULT",
      "SUMMARY"
    ];
    final bool isFolded = _foldedSections.contains(section);
    final bool isNormalSection = section.rawValue < _HomePageSection.result.rawValue;
    return TableRow(
      decoration: BoxDecoration(color: isNormalSection ? Colors.white : Theme.of(context).colorScheme.primary),
      children: [
        SizedBox(
          height: 48,
          child: isNormalSection ?
            IconButton(
              iconSize: 32,
              icon: Icon(isFolded ? Icons.arrow_right : Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
              onPressed: () => _sectionOnFolding(section)
            ) :
            Container(),
        ),
        Text(
          titles[section.rawValue],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isNormalSection ? Colors.black : Colors.white
          )
        ),
        section != _HomePageSection.summary ?
          Text(
            "Quantity",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isNormalSection ? Colors.black : Colors.white
            )
          ) :
          Container(),
        isNormalSection ?
          IconButton(onPressed: () => _addItem(section), icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary), iconSize: 32) :
          (section != _HomePageSection.summary ? const Text("Prod", textAlign: TextAlign.center) : Container()),
      ]
    );
  }

  TableRow _makeRow(_HomePageSection section, int index) {
    ProductionJob item = _dataController.items[section.rawValue][index];
    String? icon;
    Uint8List? blob;
    String prodCount = "";
    if (item.isResource) {
      Resource? resource = _dataController.getResource(item.material);
      icon = resource?.icon;
      blob = resource?.iconBlob;
    } else {
      Product? product = _dataController.getProduct(item.material);
      icon = product?.icon;
      blob = product?.iconBlob;
      if (product != null && section == _HomePageSection.result && !product.mineable) {
        prodCount = "${item.amount ~/ product.amount}";
      }
    }
    return TableRow(
      children: [
        loadIcon(icon, blob),
        TextButton(
          onPressed: () => _itemOnSelection(section, index),
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            foregroundColor: MaterialStateProperty.all(Colors.white),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
          child: Text(item.material),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(_numberFormat.format(item.amount), textAlign: TextAlign.right),
            SizedBox(width: 30, child: IconButton(
              onPressed: () => _setAmount(section, index, true),
              icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
              iconSize: 24,
              padding: EdgeInsets.zero
            )),
            SizedBox(width: 30, child: IconButton(
              onPressed: () => _setAmount(section, index, false),
              icon: Icon(Icons.remove_circle, color: Theme.of(context).colorScheme.primary),
              iconSize: 24,
              padding: EdgeInsets.zero
            ))
          ]
        ),
        section.rawValue < _HomePageSection.result.rawValue ?
          IconButton(
            onPressed: () => _removeItem(section, index),
            icon: const Icon(Icons.delete, color: Colors.red)
          ) :
          Text(prodCount, textAlign: TextAlign.center)
      ]
    );
  }

  TableRow _makeSummaryRow(int index) {
    String title = "";
    String value = "";
    switch (index) {
      case 0:
        title = "Production duration";
        value = DurationComponents.init(_dataController.productionTime).formatedString;
      case 1:
        title = "Minerals quantity [2]";
        value = _numberFormat.format(_dataController.resResourceAmount);
      case 2:
        title = "Products quantity [3]";
        value = _numberFormat.format(_dataController.resProductAmount);
      case 3:
        title = "Total quantity ([2] + [3])";
        value = _numberFormat.format(_dataController.resResourceAmount + _dataController.resProductAmount);
      default:
        break;
    }
    return TableRow(children: [
      const SizedBox(height: 32),
      Text(title, textAlign: TextAlign.left),
      Text(value, textAlign: TextAlign.right),
      Container()
    ]);
  }

  void _addItem(_HomePageSection section) {
    List<String> excludedResources = [];
    List<String> excludedProducts = [];
    for (ProductionJob item in _dataController.items[section.rawValue]) {
      if (item.isResource) {
        excludedResources.add(item.material);
      } else {
        excludedProducts.add(item.material);
      }
    }
    showDialog(
      context: context,
      builder: (_) => DataSelectionPage(
        excludedResources: excludedResources,
        excludedProducts: excludedProducts,
        completion: (Resource? resource, Product? product) {
          if (resource != null) {
            _dataController.addResource(resource, section);
            _setAmount(section, _dataController.items[section.rawValue].length - 1, null);
          }
          if (product != null) {
            _dataController.addProduct(product, section);
            _setAmount(section, _dataController.items[section.rawValue].length - 1, null);
          }
        })
    );
  }

  void _itemOnSelection(_HomePageSection section, int index) {
    _setAmount(section, index, null);
  }

  void _removeItem(_HomePageSection section, int index) {
    _dataController.items[section.rawValue].removeAt(index);
    _dataController.save();
    _calculate();
  }

  void _allClear() {
    _dataController.clear();
    _dataController.save();
    setState(() {});
  }

  void _sectionOnFolding(_HomePageSection section) {
    setState(() {
      if (_foldedSections.contains(section)) {
        _foldedSections.remove(section);
      } else {
        _foldedSections.add(section);
      }
    });
  }

  void _allFold() {
    setState(() {
       if (_foldedSections.length == 2) {
        _foldedSections.clear();
       } else {
        _foldedSections = [
          _HomePageSection.input,
          _HomePageSection.inventory
        ];
       }
    });
  }

  void _setAmount(_HomePageSection section, int index, bool? isAdd) {
    ProductionJob item = _dataController.items[section.rawValue][index];
    String title = "";
    String amount = "";
    if (isAdd != null) {
      title = isAdd ? "Increase" : "Decrease";
    } else {
      title = "Set";
      amount = "${item.amount}";
    }
    if (section == _HomePageSection.input) {
      title += " input quantity for '${item.material}'";
    } else {
      title += " inventory quantity for '${item.material}'";
    }
    ProductionJob? inventoryJob;
    if (section == _HomePageSection.result) {
      for (ProductionJob job in _dataController.items[_HomePageSection.inventory.rawValue]) {
        if (job.material == item.material && job.isResource == item.isResource) {
          inventoryJob = job;
          if (isAdd == null) amount = "${job.amount}";
          break;
        }
      }
      if ((isAdd ?? false) || amount.isEmpty) amount = "${item.amount}";
    }
    inputNumberDialogBuilder(
      context,
      title,
      amount,
      (value) {
        int res = int.parse(value);
        if (section == _HomePageSection.result) {
          if (inventoryJob == null) {
            if (item.isResource) {
              Resource resource = _dataController.getResource(item.material)!;
              _dataController.addResource(resource, _HomePageSection.inventory);
            } else {
              Product product = _dataController.getProduct(item.material)!;
              _dataController.addProduct(product, _HomePageSection.inventory);
            }
            inventoryJob = _dataController.items[_HomePageSection.inventory.rawValue][_dataController.items[_HomePageSection.inventory.rawValue].length - 1];
          }
          if (isAdd != null) {
            if (isAdd) {
              inventoryJob?.amount += res;
            } else {
              res = (inventoryJob?.amount ?? 0) - res;
              if (res < 0) res = 0;
              inventoryJob?.amount = res;
            }
          } else {
            inventoryJob?.amount = res;
          }
        } else {
          if (isAdd != null) {
            if (isAdd) {
              item.amount += res;
            } else {
              res = item.amount - res;
              if (res < 0) res = 0;
              item.amount = res;
            }
          } else {
            item.amount = res;
          }
        }
        _dataController.save();
        _calculate();
      }
    );
  }

  void _calculate() async {
    _dataController.calculate().then((value) => setState(() {}));
  }

  void _helpOnTap() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
  }

}

class _MyHomePageDataController {

  final List<List<ProductionJob>> items = [[], [], []];

  final Map<String, Resource> _cacheResources = {};
  final Map<String, Product> _cacheProducts = {};
  final DataHistory _history = DataHistory();
  int productionTime = 0;
  int resResourceAmount = 0;
  int resProductAmount = 0;

  void cacheResource(Resource resource) => _cacheResources[resource.name] = resource;
  void cacheProduct(Product product) => _cacheProducts[product.name] = product;
  Resource? getResource(String name) => _cacheResources[name];
  Product? getProduct(String name) => _cacheProducts[name];

  void addResource(Resource resource, _HomePageSection section) {
    cacheResource(resource);
    ProductionJob item = ProductionJob(
      material: resource.name,
      type: section == _HomePageSection.input ? JobType.input : JobType.inventory,
      isResource: true,
      amount: 0
    );
    items[section.rawValue].add(item);
  }

  void addProduct(Product product, _HomePageSection section) {
    cacheProduct(product);
    ProductionJob item = ProductionJob(
      material: product.name,
      type: section == _HomePageSection.input ? JobType.input : JobType.inventory,
      isResource: false,
      amount: 0
    );
    items[section.rawValue].add(item);
  }

  Future<void> loadData() async {
    clear();
    await _history.loadData();
    MaterialDatabase db = MaterialDatabase();
    List<ProductionJob> jobs = await db.loadJobs();
    List<String> resNames = [];
    List<String> prodNames = [];
    for (ProductionJob job in jobs) {
      if (job.isResource) {
        resNames.add(job.material);
      } else {
        prodNames.add(job.material);
      }
      if (job.type == JobType.input) {
        items[_HomePageSection.input.rawValue].add(job);
      } else {
        items[_HomePageSection.inventory.rawValue].add(job);
      }
    }
    List<Resource> resources = await db.loadEnableResources(included: resNames);
    List<Product> products = await db.loadEnableProducts(included: prodNames);
    for (Resource resource in resources) {
      _cacheResources[resource.name] = resource;
    }
    for (Product product in products) {
      _cacheProducts[product.name] = product;
    }
    await calculate();
  }

  void clear() {
    for (List<ProductionJob> list in items) {
      list.clear();
    }
    _cacheResources.clear();
    _cacheProducts.clear();
    _history.clear();
    productionTime = 0;
  }

  Future<void> save() async {
    List<ProductionJob> jobs = [];
    jobs.addAll(items[_HomePageSection.input.rawValue]);
    jobs.addAll(items[_HomePageSection.inventory.rawValue]);
    MaterialDatabase().saveJobs(jobs);
  }

  Future<void> calculate() async {
    items[_HomePageSection.result.rawValue].clear();
    Map<String, int> inventoryResources = {};
    Map<String, int> inventoryProducts = {};
    List<ProductionJob> prodJobQueue = [];
    for (ProductionJob job in items[_HomePageSection.inventory.rawValue]) {
      if (job.isResource) {
        inventoryResources[job.material] = job.amount;
      } else {
        inventoryProducts[job.material] = job.amount;
      }
    }
    prodJobQueue.addAll(items[_HomePageSection.input.rawValue]);
    while (prodJobQueue.isNotEmpty) {
      await _doCalculate(prodJobQueue, inventoryResources, inventoryProducts);
    }
    _sortResult();
  }

  Future<void> _doCalculate(List<ProductionJob> queue, Map<String, int> resourcesInventory, Map<String, int> productsInventory) async {
    MaterialDatabase db = MaterialDatabase();
    ProductionJob job = queue.removeAt(0);
    if (job.isResource) {
      int inventoryValue = resourcesInventory[job.material] ?? 0;
      int requiredValue = job.amount - inventoryValue;
      if (requiredValue <= 0) {
        resourcesInventory[job.material] = inventoryValue - job.amount;
      } else {
        _addResultJob(job.material, true, requiredValue);
      }
      if (!_cacheResources.containsKey(job.material)) {
        cacheResource((await db.loadEnableResources(included: [job.material]))[0]);
      }
      return;
    }

    late Product product;
    if (_cacheProducts.containsKey(job.material)) {
      product = _cacheProducts[job.material]!;
    } else {
      product = (await db.loadEnableProducts(included: [job.material]))[0];
      cacheProduct(product);
    }
    int value = productsInventory[job.material] ?? 0;
    int requiredValue = job.amount - value;
    if (requiredValue <= 0) {
      productsInventory[job.material] = value - job.amount;
      return;
    }

    if (product.mineable) {
      _addResultJob(job.material, false, requiredValue);
      return;
    }

    int amoutToProduce = 0;
    int numberOfProductionTimes = 0;
    while (amoutToProduce < requiredValue) {
      amoutToProduce += product.amount;
      numberOfProductionTimes += 1;
    }
    productsInventory[job.material] = amoutToProduce - requiredValue;
    _addResultJob(job.material, false, amoutToProduce);
    List<ProductMaterial> materials = await db.loadMaterialsForProducts([job.material]);
    for (ProductMaterial material in materials) {
      queue.add(ProductionJob(
        material: material.material,
        type: JobType.inventory,
        isResource: material.isResource,
        amount: material.amount * numberOfProductionTimes
      ));
    }
  }

  void _addResultJob(String name, bool isResource, int value) {
    bool found = false;
    for (ProductionJob existingJob in items[_HomePageSection.result.rawValue]) {
      if (existingJob.isResource == isResource && existingJob.material == name) {
        existingJob.amount += value;
        found = true;
        break;
      }
    }
    if (!found) {
      ProductionJob newJob = ProductionJob(
        material: name,
        type: JobType.inventory,
        isResource: isResource,
        amount: value
      );
      items[_HomePageSection.result.rawValue].add(newJob);
    }
  }

  void _sortResult() {
    List<ProductionJob> target = items[_HomePageSection.result.rawValue];
    List<ProductionJob> temp = [];
    List<ProductionJob> temp2 = [];
    temp.addAll(target);
    target.clear();
    for (ProductionJob job in temp.reversed) {
      if (job.isResource) {
        target.add(job);
      } else {
        temp2.add(job);
      }
    }
    target.addAll(temp2);
    productionTime = 0;
    resResourceAmount = 0;
    resProductAmount = 0;
    for (ProductionJob job in target) {
      if (job.isResource) {
        _history.addItemSecondary("${DataHistory.resourcePrefix}${job.material}");
        resResourceAmount += job.amount;
      } else {
        _history.addItemSecondary("${DataHistory.productPrefix}${job.material}");
        resProductAmount += job.amount;
        Product product = getProduct(job.material)!;
        if (!product.mineable && product.produceTime != null) {
          productionTime += (job.amount ~/ product.amount) * product.produceTime!;
        }
      }
    }
  }

}