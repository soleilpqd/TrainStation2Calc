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

  final List<Resource> _resources = [];
  final List<Product> _products = [];
  List<Resource> _allResources = [];
  List<Product> _allProducts = [];
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
    _doFilter();
  }

  @override
  Widget build(BuildContext context) {
    final numOfRows = _resources.length + _products.length;
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
              children: List<TableRow>.generate(numOfRows, (index) {
                String name = "";
                String? icon;
                Uint8List? blob;
                if (index >= _resources.length) {
                  Product product = _products[index - _resources.length];
                  name = product.name;
                  icon = product.icon;
                  blob = product.iconBlob;
                } else {
                  Resource resource = _resources[index];
                  name = resource.name;
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
    if (index >= _resources.length) {
      Product product = _products[index - _resources.length];
      widget.completion(null, product);
    } else {
      Resource resource = _resources[index];
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
    _resources.clear();
    _products.clear();
    if (_filter.isEmpty) {
      _resources.addAll(_allResources);
      _products.addAll(_allProducts);
    } else {
      for (Resource resource in _allResources) {
        if (resource.name.contains(_filter)) {
          _resources.add(resource);
        }
      }
      for (Product product in _allProducts) {
        if (product.name.contains(_filter)) {
          _products.add(product);
        }
      }
    }
  }

}
