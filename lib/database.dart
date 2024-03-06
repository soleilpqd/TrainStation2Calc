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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:train_station_2_calc/models.dart';

class MaterialDatabase {
  static final MaterialDatabase _shared = MaterialDatabase._internal();
  Database? _db;
  final int _dbVersion = 1;

  factory MaterialDatabase() {
    return _shared;
  }

  MaterialDatabase._internal();

  bool get isOpen => _db != null;

  Future<void> open() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbPath = join(await getDatabasesPath(), 'material.db');
    print("DB: $dbPath");
    _db = await openDatabase(dbPath, version: _dbVersion, onCreate: (db, ver) {
      return db.execute(
        """
        CREATE TABLE resource(
          name TEXT PRIMARY KEY,
          enable INTEGER,
          time INTEGER,
          level INTEGER,
          icon TEXT,
          icon_blob BLOB
        );
        """
      ).then((value) {
        return db.execute(
          """
          CREATE TABLE product(
            name TEXT PRIMARY KEY,
            amount INTEGER,
            enable INTEGER,
            mineable INTEGER,
            produce_time INTEGER,
            mine_time INTEGER,
            level INTEGER,
            icon TEXT,
            icon_blob BLOB
          );
          """
        );
      }).then((value) {
        return db.execute(
          """
          CREATE TABLE material(
            product TEXT NOT NULL,
            material TEXT NOT NULL,
            is_resource INTEGER,
            amount INTEGER
          );
          """
        );
      }).then((value) {
        return db.execute(
          """
          CREATE TABLE job(
            material TEXT NOT NULL,
            is_resource INTEGER,
            type INTEGER,
            amount INTEGER
          );
          """
        );
      }).then((value) => resetDatabase(database: db));
    });
  }

  void close() {
    _db?.close();
  }

  Future<void> resetDatabase({Database? database}) async {
    try {
      String json = await rootBundle.loadString("assets/materials.json");
      final data = jsonDecode(json) as Map<String, dynamic>;
      List resourcesData = data["resources"];
      List productsData = data["products"];
      List materialsData = data["materials"];
      List<Resource> resources = resourcesData.map((item) => Resource.fromJson(item)).toList();
      List<Product> products = productsData.map((item) => Product.fromJson(item)).toList();
      List<ProductMaterial> materials = materialsData.map((item) => ProductMaterial.fromJson(item)).toList();
      final db = database ?? _db!;
      await db.delete("resource")
        .then((value) => db.delete("product"))
        .then((value) => db.delete("material"))
        .then((value) => db.delete("job"))
        .then((value) {
          final batch = db.batch();
          for (final resource in resources) {
            batch.insert("resource", _mapResource(resource));
          }
          for (final product in products) {
            batch.insert("product", _mapProduct(product));
          }
          for (final material in materials) {
            batch.insert("material", _mapMaterial(material));
          }
          return batch.commit();
        });
    } catch (error) {
      print("RESET DB ERROR: $error");
    }
  }

  Map<String, Object?> _mapResource(Resource resource) => {
    "name": resource.name,
    "enable": resource.enable ? 1 : 0,
    "time": resource.time,
    "level": resource.level,
    "icon": resource.icon,
    "icon_blob": resource.iconBlob
  };

  Resource _remapResource(Map<String, Object?> record) => Resource(
    name: record["name"] as String,
    enable: (record["enable"] as int) > 0,
    time: record["time"] as int,
    level: record["level"] as int,
    icon: record["icon"] as String?,
    iconBlob: record["icon_blob"] as Uint8List?
  );

  Map<String, Object?> _mapProduct(Product product) => {
    "name": product.name,
    "amount": product.amount,
    "enable": product.enable ? 1 : 0,
    "mineable": product.mineable ? 1 : 0,
    "produce_time": product.produceTime,
    "mine_time": product.mineTime,
    "level": product.level,
    "icon": product.icon,
    "icon_blob": product.iconBlob
  };

  Product _remapProduct(Map<String, Object?> record) => Product(
    name: record["name"] as String,
    amount: record["amount"] as int,
    enable: (record["enable"] as int) > 0,
    mineable: (record["mineable"] as int) > 0,
    produceTime: record["produce_time"] as int?,
    mineTime: record["mine_time"] as int?,
    level: record["level"] as int,
    icon: record["icon"] as String?,
    iconBlob: record["icon_blob"] as Uint8List?
  );

  Map<String, Object?> _mapMaterial(ProductMaterial material) => {
    "product": material.product,
    "material": material.material,
    "is_resource": material.isResource ? 1 : 0,
    "amount": material.amount
  };

  ProductMaterial _remapMaterial(Map<String, Object?> record) => ProductMaterial(
    product: record["product"] as String,
    material: record["material"] as String,
    amount: record["amount"] as int,
    isResource: (record["is_resource"] as int) > 0
  );

  Map<String, Object?> _mapJob(ProductionJob job) => {
    "material": job.material,
    "is_resource": job.isResource ? 1 : 0,
    "type": job.type.rawValue,
    "amount": job.amount
  };

  ProductionJob _remapJob(Map<String, Object?> record) => ProductionJob(
    material: record["material"] as String,
    type: JobType.init(record["type"] as int),
    isResource: (record["is_resource"] as int) > 0,
    amount: record["amount"] as int
  );

  Future<List<Resource>> loadAllResources() async {
    List<Map<String, Object?>> listRaw = await _db!.query("resource", orderBy: "level ASC, name ASC");
    return listRaw.map((item) => _remapResource(item)).toList();
  }

  Future<List<Product>> loadAllProducts() async {
    List<Map<String, Object?>> listRaw = await _db!.query("product", orderBy: "level ASC, name ASC");
    return listRaw.map((item) => _remapProduct(item)).toList();
  }

  String _buildArrayQuery(int length) {
    String result = "(";
    for (int idx = 0; idx < length; idx += 1) {
      if (idx == length - 1) {
        result += "?";
      } else {
        result += "?, ";
      }
    }
    result += ")";
    return result;
  }

  String _buildWhereStatement(List<String>? excluded, List<String>? included, bool enable, List<String> whereArgs) {
    String whereStatment = enable ? "enable > 0" : "";
    if (excluded != null && excluded.isNotEmpty) {
      if (whereStatment.isNotEmpty) {
        whereStatment += " AND ";
      }
      whereStatment += "name NOT IN ${_buildArrayQuery(excluded.length)}";
      whereArgs.addAll(excluded);
    }
    if (included != null && included.isNotEmpty) {
      if (whereStatment.isNotEmpty) {
        whereStatment += " AND ";
      }
      whereStatment += "name IN ${_buildArrayQuery(included.length)}";
      whereArgs.addAll(included);
    }
    return whereStatment;
  }

  Future<List<Resource>> loadEnableResources({List<String>? excluded, List<String>? included, bool enable = true}) async {
    List<String> whereArgs = [];
    String whereStatment = _buildWhereStatement(excluded, included, enable, whereArgs);
    List<Map<String, Object?>> listRaw = await _db!.query("resource", where: whereStatment, whereArgs: whereArgs, orderBy: "level ASC, name ASC");
    return listRaw.map((item) => _remapResource(item)).toList();
  }

  Future<List<Product>> loadEnableProducts({List<String>? excluded, List<String>? included, bool enable = true}) async {
    List<String> whereArgs = [];
    String whereStatment = _buildWhereStatement(excluded, included, enable, whereArgs);
    List<Map<String, Object?>> listRaw = await _db!.query("product", where: whereStatment, whereArgs: whereArgs, orderBy: "level ASC, name ASC");
    return listRaw.map((item) => _remapProduct(item)).toList();
  }

  Future<void> updateResource(Resource resource) => _db!.update("resource", _mapResource(resource), where: "name = ?", whereArgs: [resource.name]);

  Future<void> updateProduct(Product product) => _db!.update("product", _mapProduct(product), where: "name = ?", whereArgs: [product.name]);

  Future<void> updateResources(List<Resource> resources) async {
    final batch = _db!.batch();
    for (final resource in resources) {
      batch.update("resource", _mapResource(resource), where: "name = ?", whereArgs: [resource.name]);
    }
    await batch.commit();
  }

  Future<void> updateProducts(List<Product> products) async {
    final batch = _db!.batch();
    for (final product in products) {
      batch.update("product", _mapProduct(product), where: "name = ?", whereArgs: [product.name]);
    }
    await batch.commit();
  }

  /// Load ingredients to produce given products
  Future<List<ProductMaterial>> loadMaterialsForProducts(List<String> products) async {
    String whereStatment = "product IN ${_buildArrayQuery(products.length)}";
    List<Map<String, Object?>> listRaw = await _db!.query("material", where: whereStatment, whereArgs: products);
    return listRaw.map((element) => _remapMaterial(element)).toList();
  }

  /// Load products which depend on given resources
  Future<List<ProductMaterial>> loadMaterialsForResources(List<String> resources, bool? filter) async {
    String whereStatment = "material IN ${_buildArrayQuery(resources.length)}";
    if (filter != null) {
      if (filter) {
        whereStatment += " AND is_resource > 0";
      } else {
        whereStatment += " AND is_resource = 0";
      }
    }
    List<Map<String, Object?>> listRaw = await _db!.query("material", where: whereStatment, whereArgs: resources);
    return listRaw.map((element) => _remapMaterial(element)).toList();
  }

  Future<void> saveJobs(List<ProductionJob> jobs) async {
    Database db = _db!;
    await db.delete("job");
    if (jobs.isEmpty) { return; }
    Batch batch = db.batch();
    for (ProductionJob job in jobs) {
      batch.insert("job", _mapJob(job));
    }
    await batch.commit();
  }

  Future<List<ProductionJob>> loadJobs() async {
    Database db = _db!;
    List<ProductionJob> result = (await db.rawQuery("""
SELECT job.* FROM job
LEFT OUTER JOIN resource ON job.material == resource.name
LEFT OUTER JOIN product ON job.material == product.name
WHERE product.enable > 0 OR resource.enable > 0
""")).map((element) => _remapJob(element)).toList();
    return result;
  }

  Future<bool> insertResource(Resource resource) async {
    final Database db = _db!;
    try {
      await db.insert("resource", _mapResource(resource));
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> deleteResource(String name) async {
    final Database db = _db!;
    try {
      await db.delete("resource", where: "name == ?", whereArgs: [name]);
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> insertProduct(Product product) async {
    final Database db = _db!;
    try {
      await db.insert("product", _mapProduct(product));
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> deleteProduct(String name) async {
    final Database db = _db!;
    try {
      await db.delete("product", where: "name == ?", whereArgs: [name]);
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> insertMaterial(ProductMaterial material) async {
    final Database db = _db!;
    try {
      await db.insert("material", _mapMaterial(material));
      return true;
    } on Exception {
      return false;
    }
  }

}