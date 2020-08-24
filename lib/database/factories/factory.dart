import 'package:flutter/foundation.dart';
import 'package:flutter_eloquent/query/model.dart';
import 'package:flutter_eloquent/query/db.dart';
import 'factory_builder.dart';

class EloquentFactory {

  /// The model definitions in the container.
  @protected
  Map<Type, FactoryCallable> definitions = {};

  EloquentFactory();

  /// Define a class with a given set of attributes.
  EloquentFactory define(Type $class, FactoryCallable attributes) {
    definitions[$class] = attributes;

    return this;
  }

  /// Create an instance of the given model and persist it to the database.
  Model create(Type $class, [Map<String, dynamic> attributes = const {}]) {
    return of($class).create();
  }

  /// Create an instance of the given model.
  Model make(Type $class, [Map<String, dynamic> attributes = const {}]) {
    return of($class).make();
  }

  /// Create a builder for the given model.
  FactoryBuilder of(Type $class) {
    return new FactoryBuilder(
      $class: $class,
      connection: DatabaseConfig().db,
    );
  }
}

/// A shortcut that provide an instance of the factory..
EloquentFactory factory() => new EloquentFactory();


typedef Map<String, dynamic> FactoryCallable();
