import 'package:flutter/foundation.dart' show ValueGetter;

abstract class ContainerInterface {
  E get<E>(String id);

  bool has(String id);

  void set<E>(String id, ValueGetter<Object> callback);
}
