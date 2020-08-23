import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart' as t;
import 'package:flutter_test/flutter_test.dart';

import 'package:sqflite_common/sqlite_api.dart' as sqliteApi;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import 'package:flutter_eloquent/flutter_eloquent.dart';
import 'package:sqlcool/sqlcool.dart' as sqlcool;

sqliteApi.Database db;

Future<sqliteApi.Database> connectDb() async {
  if (db == null) {
    // ffi.sqfliteFfiInit();
    db = await ffi.databaseFactoryFfi.openDatabase(sqliteApi.inMemoryDatabasePath);
    migrate();
    return db;
  }
  return db;
}

Builder get query => new Builder(db).withoutPreparedStatements();

void migrate() {
  // define the database schema
  sqlcool.DbTable product = sqlcool.DbTable("products")
    ..varchar("name", unique: true)
    ..integer("price")
    ..text("description", nullable: true)
    // ..foreignKey("category_id", reference: 'categories', onDelete: sqlcool.OnDelete.cascade)
    ..index("name");
  List<sqlcool.DbTable> schema = [product];

  // print(product.queryString());

  schema.forEach((schema) => db.execute(schema.queryString()));
}

void main() {
  t.setUp(() async {
    await connectDb();
  });

  test('simple sqflite example', () async {
    var db = await connectDb();
    expect(await db.getVersion(), 0);
    await db.close();
  });

  test('Test "Select" grammar verb', () {
    final q = query.table('posts').select(['name']);

    t.expect(q.toRawSql(), "SELECT name FROM posts");
  });

  test("Test 'where' grammar verb", () {
    Builder q = query
      .table('posts')
      .select()
      .where('id', '=', 1);
    t.expect(q.toRawSql(), "SELECT * FROM posts WHERE id = 1");

    // test empty operator and "AND" boolean.
    q = query
      .table('posts')
      .select()
      .where('id', 1)
      .where('name', 'Post 1');
    t.expect(q.toRawSql(), "SELECT * FROM posts WHERE id = 1 AND name = 'Post 1'");

    final now = DateTime.now().toIso8601String();
    // Test or where
    q = query
      .table('posts')
      .select()
      .where('id', '>', 1)
      .orWhere('name', 'Post 1')
      .orWhere('created_at', now)
      .where('deleted_at', '!=', null)
      .where('is_active', true)
      .orWhere('is_admin', true);
    t.expect(q.toRawSql(), "SELECT * FROM posts"
      " WHERE (id > 1 OR name = 'Post 1' OR created_at = '$now')"
      " AND (deleted_at is not NULL)"
      " AND (is_active = 1 OR is_admin = 1)"
    );

    t.expect(q.withPreparedStatements().toRawSql(), "SELECT * FROM posts"
      " WHERE (id > ? OR name = ? OR created_at = ?)"
      " AND (deleted_at is not ?)"
      " AND (is_active = ? OR is_admin = ?)"
    );
  });

  test("Test count and create", () async {
    var q = query.table('products').select();
    t.expect(await q.count(), 0);

    await query.table('products')
      .withoutPreparedStatements()
      .create({
        'name': 'A name',
        'price': 562,
        'description': 'Your desc!!!'
    });
    await query.table('products')
      .withPreparedStatements()
      .create({
        'name': 'A name 2',
        'price': 562,
        'description': 'Your desc!!!'
    });
    t.expect(await q.count(), 2);
  });
}
