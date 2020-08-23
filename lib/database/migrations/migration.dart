import 'package:flutter_eloquent/query/db.dart';
import 'package:sqflite_common/sqlite_api.dart';

abstract class Migration {

  // The name of the database connection to use.
  Database connection = Config().db;

  /// Run the migrations.
  void up();

  /// Reverse the migrations.
  void down();

}
