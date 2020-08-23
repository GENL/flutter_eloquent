import 'package:flutter_eloquent/query/builder.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqliteApi;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// A class containing query helpers.
class Db {

  /// Helper to get an instance of the query builder.
  static Builder table(String table)
    => new Builder(Config().db).table(table).withPreparedStatements();
}


/// Global singleton database configuration.
class Config {
  static Config _instance;

  /// The database version
  /// When the database version change, the migrations are auto run.
  int version = 1;

  sqliteApi.Database db;

  Config._({
    this.version,
  });

  factory Config({
    int dbVersion,
  }) {
    if (_instance == null) {
      _instance = Config._(version: dbVersion);
    }

    return _instance;
  }

  /// In memory database is useful for testing purpose.
  /// Get the database for testing purpose.
  static Future<sqliteApi.Database> getInMemoryDatabase(
      {sqliteApi.OpenDatabaseOptions options}) {
    return ffi.databaseFactoryFfi
        .openDatabase(sqliteApi.inMemoryDatabasePath, options: options);
  }

  /// Opens the database and return an instance of the db.
  /// To use In memory database for testing, just passe null to [databasePath].
  Future<sqliteApi.Database> openDatabase(String databasePath,
      {sqliteApi.OpenDatabaseOptions options}) async {
    db = databasePath == null
        ? await getInMemoryDatabase(options: options)
        : await ffi.databaseFactoryFfi.openDatabase(databasePath);
    return db;
  }
}
