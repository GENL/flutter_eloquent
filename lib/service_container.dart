
import 'package:flutter/cupertino.dart';

/// The service container is a tool for managing class dependencies
class ServiceContainer {
  static ServiceContainer _instance = new ServiceContainer._();

  /// Dependencies that was resolved.
  List<ContainerDependency> _resolved = [];

  ServiceContainer._();

  /// The service container is a tool for managing class dependencies
  factory ServiceContainer() => _instance;

  /// Gets a bound dependency.
  Object get(Type type) {
    ContainerDependency containerDependency = _resolved.firstWhere(
        (dependency) => dependency.type == type, orElse: () => null);

    if (containerDependency != null) {
      dynamic result;
      if (containerDependency.singleton) result = containerDependency.result;
      else result = containerDependency.constructDependencyCallback();
      return result;
    }

    return null;
  }

  /// Binds a dependency in the container.
  void bind(ValueGetter<Object> callback) {
    _addDependency(callback, false);
  }

  /// Binds a singleton dependency in the container.
  void singleton(ValueGetter<Object> callback) {
    _addDependency(callback, true);
  }

  void _addDependency(ValueGetter<dynamic> callback, bool singleton) {
    var result = callback();

    if (isBound(result.runtimeType)) return;

    _resolved.add(new ContainerDependency(
      type: result.runtimeType,
      constructDependencyCallback: callback,
      singleton: singleton
    ));
  }

  /// Check a dependency is bound
  bool isBound(Type type) {
    return get(type) != null;
  }
}


class ContainerDependency {
  /// The callback that returns the container.
  ValueGetter<Object> constructDependencyCallback;

  /// The type of the object returned by [constructDependencyCallback].
  /// This value is used to retrieve a dependency.
  Type type;

  bool singleton;

  /// The constructed dependency.
  Object result;

  ContainerDependency({
    this.constructDependencyCallback,
    this.type,
    this.singleton = false
  }) {
    result = constructDependencyCallback();
    assert(result != null);
  }
}
