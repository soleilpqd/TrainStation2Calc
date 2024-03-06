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

  const DataSelectionPage({super.key, required this.completion, required this.excludedResources, required this.excludedProducts});

  @override
  State<StatefulWidget> createState() => _DataSelectionPageState();
}

class _DataSelectionPageState extends State<DataSelectionPage> {

  List<Resource> resources = [];
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadData().then((value) => setState(() {}));
  }

  Future<void> _loadData() async {
    final db = MaterialDatabase();
    resources = await db.loadEnableResources(excluded: widget.excludedResources);
    products = await db.loadEnableProducts(excluded: widget.excludedProducts);
  }

  @override
  Widget build(BuildContext context) {
    final numOfRows = resources.length + products.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Data selection")
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
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
              if (index >= resources.length) {
                Product product = products[index - resources.length];
                name = product.name;
                icon = product.icon;
                blob = product.iconBlob;
              } else {
                Resource resource = resources[index];
                name = resource.name;
                icon = resource.icon;
                blob = resource.iconBlob;
              }
              return _makeRow(name, icon, blob, index);
            }),
          ),
        ],
      )
    );
  }

  TableRow _makeRow(String name, String? icon, Uint8List? blob, int index) {
    return TableRow(
      children: [
        loadIcon(icon, blob),
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
    if (index >= resources.length) {
      Product product = products[index - resources.length];
      widget.completion(null, product);
    } else {
      Resource resource = resources[index];
      widget.completion(resource, null);
    }
  }

}
