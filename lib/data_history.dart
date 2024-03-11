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

import 'package:shared_preferences/shared_preferences.dart';

class DataHistory {
  static final DataHistory _shared = DataHistory._internal();
  SharedPreferences? _prefs;

  static const String resourcePrefix = "R:";
  static const String productPrefix = "P:";
  static const String historyKey = "selection_history";
  List<String> items = [];

  factory DataHistory() {
    return _shared;
  }

  DataHistory._internal();

  Future<void> loadData() async {
    _prefs = await SharedPreferences.getInstance();
    items = _prefs?.getStringList(historyKey) ?? [];
  }

  static String nameFromHistoryItem(String item) => item.substring(2);

  void addItem(String item) {
    final int index = items.indexOf(item);
    if (index >= 0) {
      items.removeAt(index);
    }
    items.insert(0, item);
    _prefs?.setStringList(historyKey, items);
  }

  void addItemSecondary(String item) {
    final int index = items.indexOf(item);
    if (index <= 1 && index >= 0) {
      return;
    }
    if (index > 1) {
      items.removeAt(index);
    }
    if (items.length > 1) {
      items.insert(1, item);
    } else {
      items.add(item);
    }
    _prefs?.setStringList(historyKey, items);
  }

  void clear() {
    items.clear();
    _prefs?.remove(historyKey);
  }

}
