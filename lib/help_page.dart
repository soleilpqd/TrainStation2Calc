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
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HelpPage extends StatefulWidget {

  const HelpPage({super.key});

  @override
  State<StatefulWidget> createState() => _HelpPageState();

}

class _HelpPageState extends State<HelpPage> {

  String _data = "";
  int _index = 0;
  final List<String> _titles = ["Start", "Main Screen", "Selection Screen", "Database Screen", "Product Detail Screen"];
  final List<String> _files = ["index", "main_screen", "selection_screen", "database_screen", "product_detail"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    rootBundle.loadString("assets/manual/${_files[_index]}.md").then((value) => setState(() {
      _data = value;
    }));
  }

  @override
  Widget build(BuildContext context) {
    List<TextButton> headerItems = [];
    for (int idx = 0; idx < _files.length; idx += 1) {
      TextStyle? titleStyle;
      if (idx == _index) {
        titleStyle = const TextStyle(fontWeight: FontWeight.bold, color: Colors.white);
      }
      headerItems.add(TextButton(
        onPressed: () => _sectionOnTap(idx),
        child: Text(_titles[idx], style: titleStyle)
      ));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Manual\n(5 pages)", textAlign: TextAlign.center)
      ),
      body: Column(children: [
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: headerItems
          )
        ),
        Expanded(child: Markdown(data: _data))
      ])
    );
  }

  void _sectionOnTap(int index) {
    _index = index;
    _loadData();
  }

}
