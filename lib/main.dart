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
import 'package:intl/intl.dart';
import 'package:train_station_2_calc/database.dart';
import 'package:train_station_2_calc/database_page.dart';
import 'package:train_station_2_calc/data_selection_page.dart';
import 'package:train_station_2_calc/dialogs.dart';
import 'package:train_station_2_calc/models.dart';

void main() {
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
  result(rawValue: 2);

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
  Widget build(BuildContext context) {
    final List<int> lengths = [
      _foldedSections.contains(_HomePageSection.input) ? 0 : _dataController.items[_HomePageSection.input.rawValue].length,
      _foldedSections.contains(_HomePageSection.inventory) ? 0 : _dataController.items[_HomePageSection.inventory.rawValue].length,
      _dataController.items[_HomePageSection.result.rawValue].length,
    ];
    int numOfRows = lengths.length;
    for (int item in lengths) {
      numOfRows += item;
    }
    if (!MaterialDatabase().isOpen) {
      return Container(
        color: Theme.of(context).colorScheme.primary,
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DatabasePage()));
            }
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
              2: FixedColumnWidth(90),
              3: FixedColumnWidth(40),
            },
            children: List<TableRow>.generate(numOfRows, (index) {
              int sect = 0;
              int row = -1;
              int temp = index;
              int lIdx = 0;
              while (temp >= 0 && lIdx < lengths.length) {
                temp -= lengths[lIdx] + 1;
                lIdx += 1;
                if (temp >= 0) {
                  sect += 1;
                }
              }
              temp = 0;
              for (int idx = 0; idx < sect; idx += 1) {
                temp += lengths[idx] + 1;
              }
              row = index - temp - 1;
              _HomePageSection section = _HomePageSection.init(sect);
              if (row < 0) {
                return _makeSectionHeader(section);
              }
              return _makeRow(section, row);
            }),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  TableRow _makeSectionHeader(_HomePageSection section) {
    final List<String> titles = [
      "INPUT",
      "INVENTORY",
      "RESULT"
    ];
    final bool isFolded = _foldedSections.contains(section);
    return TableRow(
      decoration: BoxDecoration(color: section.rawValue < _HomePageSection.result.rawValue ? Colors.white : Theme.of(context).colorScheme.primary),
      children: [
        SizedBox(
          height: 48,
          child: section.rawValue < _HomePageSection.result.rawValue ?
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
            color: section.rawValue < _HomePageSection.result.rawValue ? Colors.black : Colors.white
          )
        ),
        Text(
          "Quantity",
          textAlign: TextAlign.right,
          style: TextStyle(
            color: section.rawValue < _HomePageSection.result.rawValue ? Colors.black : Colors.white
          )
        ),
        section.rawValue < _HomePageSection.result.rawValue ?
          IconButton(onPressed: () => _addItem(section), icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary), iconSize: 32) :
          const Text("Prod", textAlign: TextAlign.center),
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
        Text(_numberFormat.format(item.amount), textAlign: TextAlign.right),
        section.rawValue < _HomePageSection.result.rawValue ?
          IconButton(
            onPressed: () => _removeItem(section, index),
            icon: const Icon(Icons.delete, color: Colors.red)
          ) :
          Text(prodCount, textAlign: TextAlign.center)
      ]
    );
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
      builder: (ctx) => DataSelectionPage(
        excludedResources: excludedResources,
        excludedProducts: excludedProducts,
        completion: (Resource? resource, Product? product) {
          if (resource != null) {
            _dataController.addResource(resource, section);
            _setAmount(section, _dataController.items[section.rawValue].length - 1);
          }
          if (product != null) {
            _dataController.addProduct(product, section);
            _setAmount(section, _dataController.items[section.rawValue].length - 1);
          }
        })
    );
  }

  void _itemOnSelection(_HomePageSection section, int index) {
    _setAmount(section, index);
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

  void _setAmount(_HomePageSection section, int index) {
    ProductionJob item = _dataController.items[section.rawValue][index];
    inputNumberDialogBuilder(
      context,
      "Input quantity for '${item.material}'",
      "${item.amount}",
      (value) {
        int res = int.parse(value);
        item.amount = res;
        _dataController.save();
        _calculate();
      }
    );
  }

  void _calculate() async {
    _dataController.calculate().then((value) => setState(() {}));
  }

}

class _MyHomePageDataController {

  final List<List<ProductionJob>> items = [[], [], []];

  final Map<String, Resource> _cacheResources = {};
  final Map<String, Product> _cacheProducts = {};

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
  }

}