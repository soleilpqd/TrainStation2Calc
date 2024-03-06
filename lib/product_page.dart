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

import 'package:flutter/material.dart';
import 'package:train_station_2_calc/models.dart';

class ProductPage extends StatefulWidget {

  final Product product;

  const ProductPage({super.key, required this.product});

  @override
  State<StatefulWidget> createState() => _ProductPageState();

}

class _ProductPageState extends State<ProductPage> {

  final _ProductPageDataController _dataController = _ProductPageDataController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext wgBuildCtx) {
    final int numOfRows = 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(wgBuildCtx).colorScheme.primary,
        title: Text(widget.product.name.toUpperCase())
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
              SizedBox(
                width: 40,
                child: Container(),
              )
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
                0: FixedColumnWidth(50),
                1: FlexColumnWidth()
              },
              children: List<TableRow>.generate(numOfRows, (index) {
                return TableRow();
              }),
            ),
          ],
        ))
      ])
    );
  }

  void _addMaterialOnTap() {

  }

}

class _ProductPageDataController {

}