import 'package:flutter_eloquent/query/builder.dart';
// import 'package:sqflite_common/sqlite_api.dart' as sqliteApi;
// import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite/sqflite.dart' as sqliteApi;

/// A class containing query helpers.
class Db {
  /// Helper to get an instance of the query builder.
  static Builder table(String table)
    => new Builder(DatabaseConfig().db).table(table).withPreparedStatements();
}


/// Global singleton database configuration.
class DatabaseConfig {
  static DatabaseConfig _instance;

  // The database version
  // When the database version change, the migrations are auto run.
  // int version = 1;

  sqliteApi.OpenDatabaseOptions options;

  sqliteApi.Database db;

  DatabaseConfig._();

  factory DatabaseConfig() {
    if (_instance == null) {
      _instance = DatabaseConfig._();
    }

    return _instance;
  }

  /// In memory database is useful for testing purpose.
  /// Get the database for testing purpose.
  Future<sqliteApi.Database> getInMemoryDatabase(
      {sqliteApi.OpenDatabaseOptions options}) {
    return openDatabase(sqliteApi.inMemoryDatabasePath, options: options);
  }

  /// Opens the database and return an instance of the db.
  /// To use In memory database for testing, just passe null to [databasePath].
  Future<sqliteApi.Database> openDatabase(String databasePath,
      {sqliteApi.OpenDatabaseOptions options}) async {
    db = databasePath == null
        ? await getInMemoryDatabase(options: options)
        : await _openDatabase(databasePath, options: options);
    return db;
  }

  Future<sqliteApi.Database> _openDatabase(String path, {sqliteApi.OpenDatabaseOptions options}) {
    if (db != null) return Future.value(db);

    this.options = options = sqliteApi.OpenDatabaseOptions(
      version: options?.version ?? 1,
      readOnly: options?.readOnly ?? false,
      onConfigure: options?.onConfigure,
      onCreate: options?.onCreate,
      onDowngrade: options?.onDowngrade,
      onOpen: options?.onOpen,
      onUpgrade: options?.onUpgrade,
      singleInstance: options?.singleInstance ?? true
    );

    return sqliteApi.openDatabase(
      sqliteApi.inMemoryDatabasePath,
      version: this.options.version,
      readOnly: this.options.readOnly,
      onConfigure: this.options.onConfigure,
      onCreate: this.options.onCreate,
      onDowngrade: this.options.onDowngrade,
      onOpen: this.options.onOpen,
      onUpgrade: this.options.onUpgrade,
      singleInstance: this.options.singleInstance
    );
  }
}
