import 'dart:async';
import 'dart:core';
import 'package:flutter_eloquent/json_parser/json_parsable.dart';
import 'package:flutter_eloquent/container_/container.dart';
import 'builder0.dart';
// import 'db.dart';

class Model<E> with JsonParsable, JsonHelpable<Map<String, dynamic>> {
  Builder get query {
    try {
      if (_db != null) return _db;
      _db = Builder(Container().get("pdo"));
      return _db;
    } catch (e) {
      return null;
    }
    // return Db.table(getTableByClassName())
  }

  set query(Builder v) => _db = v;

  Builder _db;

  String view = "";

  String table;
  String id;

  List<String> get fillable => null;

  Fun<E> _fromJson;

  Model([Fun<E> _fromJson]) {
    this._fromJson = (json) {
      if (json.containsKey('id')) json['id'] = json['id'].toString();
      return _fromJson(json);
    };
    if (this.table == null) this.table = this.getTableByClassName();
  }

  Future find(int id) async {
    List response = await this
        .query
        .table(this.table)
        .where("id", "$id")
        .select()
        .execute<E>(/*_fromJson*/);
    return this._fromJson(response[0]);
  }

  Model where(String field, [String operator, String values]) {
    this.query = this.query.where(field, operator, values);
    return this;
  }

  Future<bool> update(Map<String, dynamic> data) async {
    await this.query.table(this.table).update(filters(data)).execute();
    return true;
  }

  Model whereRaw(String field, [String operator, String values]) {
    this.query = this.query.whereRaw(field, operator, values);
    return this;
  }

  Model orderBy(String field, [String order = "ASC"]) {
    this.query = this.query.orderBy(field, order);
    return this;
  }

  Model limit(String limit) {
    this.query = this.query.limit(limit);
    return this;
  }

  Future<List> get([List fields]) async {
    List response =
        await this.query.table(this.table).select(fields).execute<E>(/*_fromJson*/);
    response = response.map((res) => dataParser(res)).toList();
    return response.map((row) => this._fromJson(row)).toList();
  }

  Future<dynamic> first([List fields]) async {
    List response = await this
        .query
        .table(this.table)
        .limit("1")
        .select(fields)
        .execute<E>(/*_fromJson*/);
    response = response.map((res) => dataParser(res)).toList();
    if (response.isEmpty) return null;
    return this._fromJson(response[0]);
  }

  String getTableByClassName() {
    return this.runtimeType.toString().toLowerCase() + "s";
  }

  Future delete() {
    return this
        .query
        .table(this.table)
        .where("id", "${this.id}")
        .limit("1")
        .execute<E>(/*_fromJson*/);
  }

  Map<String, dynamic> filters(Map<String, dynamic> json) {
    if (fillable == null) return json;
    var tmp = Map<String, dynamic>();
    fillable.forEach((e) {
      if(json.containsKey(e))
      tmp[e] = json[e];
    });
    return tmp;
  }

  Future<bool> save() async {
    await this.destroy();
    var data = this.toJson();
    await this.query.table(this.table).create(filters(data)).execute();
    return true;
  }

  Future<bool> destroy() async {
    await this.query.table(this.table).where("id", "${this.id}").delete().execute();
    return true;
  }

  Map<String, dynamic> toJson() => {};

  static int getTotal(Map<String, dynamic> data) {
    if (data == null || !(data is Map) || data['paginatorInfo'] == null)
      return null;
    return data['paginatorInfo']['total'];
  }

  bool animated = false;
}
