import 'package:flutter/foundation.dart';
import 'package:flutter_eloquent/query/model.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'factory.dart';

class FactoryBuilder {
  /// The model being built.
  Type $class;

  /// The model definitions in the container.
  @protected
  Map<Type, FactoryCallable> definitions = {};

  /// The database connection on which the model instance should be persisted.
  Database connection;

  /// The number of models to build.
  int amount = 1;


  /// Create an new builder instance.
  FactoryBuilder({
    this.$class,
    this.definitions,
    this.amount,
    this.connection
  });


  /// Create a collection of models.
  dynamic make() {
    if (amount == null || amount <= 1) {
      // Return the model
    }
    // return list of models.
  }

  /// Create a collection of models and persist them to the database.
  dynamic create() {
    dynamic model = make();

    // Persist it.
  }
}
