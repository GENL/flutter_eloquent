class NotFoundException implements Exception {
  final String id;
  NotFoundException(String id) : id = id;

  String toString() {
    return "Exception: $id not found!";
  }
}
