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

class MarkdownPage extends StatefulWidget {

  const MarkdownPage({super.key});

  @override
  State<StatefulWidget> createState() => _MarkdownPageState();

}

class _MarkdownPageState extends State<MarkdownPage> {

  String _data = "";

  @override
  void initState() {
    super.initState();
    rootBundle.loadString("assets/manual/end_user_manual.md").then((value) => setState(() {
      _data = value;
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Center(child: Text("Manual"))
      ),
      body: Markdown(data: _data)
    );
  }

}
