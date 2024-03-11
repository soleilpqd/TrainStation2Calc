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
import 'package:flutter/material.dart';
import 'package:train_station_2_calc/data_history.dart';
import 'package:train_station_2_calc/database.dart';
import 'package:train_station_2_calc/models.dart';

class DataSelectionPage extends StatefulWidget {

  final Function(Resource?, Product?) completion;
  final List<String> excludedResources;
  final List<String> excludedProducts;
  final bool isEnableOnly;

  const DataSelectionPage({super.key, required this.completion, required this.excludedResources, required this.excludedProducts, this.isEnableOnly = true});

  @override
  State<StatefulWidget> createState() => _DataSelectionPageState();
}

class _DataSelectionPageState extends State<DataSelectionPage> {

  final List<String> _items = [];
  List<Resource> _allResources = [];
  List<Product> _allProducts = [];
  final DataHistory _history = DataHistory();
  String _filter = "";

  @override
  void initState() {
    super.initState();
    _loadData().then((value) => setState(() {}));
  }

  Future<void> _loadData() async {
    final db = MaterialDatabase();
    _allResources = await db.loadEnableResources(excluded: widget.excludedResources, enable: widget.isEnableOnly);
    _allProducts = await db.loadEnableProducts(excluded: widget.excludedProducts, enable: widget.isEnableOnly);
    await _history.loadData();
    _doFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Data selection")
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
          padding: const EdgeInsets.all(8),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Table(
              border: const TableBorder(horizontalInside: BorderSide(color: Colors.grey, width: 0.5)),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const <int, TableColumnWidth>{
                0: FixedColumnWidth(80),
                1: FlexColumnWidth()
              },
              children: List<TableRow>.generate(_items.length, (index) {
                String item = _items[index];
                String name = DataHistory.nameFromHistoryItem(item);
                String? icon;
                Uint8List? blob;
                if (item.startsWith(DataHistory.productPrefix)) {
                  Product product = _allProducts.firstWhere((element) => element.name == name);
                  icon = product.icon;
                  blob = product.iconBlob;
                } else if (item.startsWith(DataHistory.resourcePrefix)) {
                  Resource resource = _allResources.firstWhere((element) => element.name == name);
                  icon = resource.icon;
                  blob = resource.iconBlob;
                }
                return _makeRow(name, icon, blob, index);
              }),
            ),
          ],
        )
      )
      ])
    );
  }

  TableRow _makeRow(String name, String? icon, Uint8List? blob, int index) {
    return TableRow(
      children: [
        IconButton(
          onPressed: () => _rowOnSelection(index),
          icon: loadIcon(icon, blob),
          style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.transparent)),
        ),
        TextButton(
          onPressed: () => _rowOnSelection(index),
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            foregroundColor: MaterialStateProperty.all(Colors.white),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
          child: Text(name),
        )
      ]
    );
  }

  void _rowOnSelection(int index) {
    Navigator.of(context).pop();
    String item = _items[index];
    String name = DataHistory.nameFromHistoryItem(item);
    _history.addItem(item);
    if (item.startsWith(DataHistory.productPrefix)) {
      Product product = _allProducts.firstWhere((element) => element.name == name);
      widget.completion(null, product);
    } else if (item.startsWith(DataHistory.resourcePrefix)) {
      Resource resource = _allResources.firstWhere((element) => element.name == name);
      widget.completion(resource, null);
    }
  }

  void _filterTextOnChange(String value) {
    setState(() {
      _filter = value.trim().toLowerCase();
      _doFilter();
    });
  }

  void _doFilter() {
    _items.clear();
    final List<Resource> tempResources = [];
    tempResources.addAll(_allResources);
    final List<Product> tempProducts = [];
    tempProducts.addAll(_allProducts);

    for (String item in _history.items) {
      final String name = item.substring(2);
      final bool isValid = (_filter.isNotEmpty && name.contains(_filter)) || _filter.isEmpty;
      if (isValid) {
        if (item.startsWith(DataHistory.resourcePrefix)) {
          final int index = tempResources.indexWhere((element) => element.name == name);
          if (index >= 0) {
            _items.add(item);
            tempResources.removeAt(index);
          }
        } else if (item.startsWith(DataHistory.productPrefix)) {
          final int index = tempProducts.indexWhere((element) => element.name == name);
          if (index >= 0) {
            _items.add(item);
            tempProducts.removeAt(index);
          }
        }
      }
    }
    for (Resource resource in tempResources) {
      if (_filter.isEmpty || (_filter.isNotEmpty && resource.name.contains(_filter))) {
        _items.add("${DataHistory.resourcePrefix}${resource.name}");
      }
    }
    for (Product product in tempProducts) {
      if (_filter.isEmpty || (_filter.isNotEmpty && product.name.contains(_filter))) {
        _items.add("${DataHistory.productPrefix}${product.name}");
      }
    }
  }

}
