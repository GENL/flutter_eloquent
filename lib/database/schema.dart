class Schema {

  Schema();

  enableForeignKeyConstraints() {

  }

  disableForeignKeyConstraints() {}

  bool hasTable(String table) {}

  bool hasColumn(String table, String column) {}

  void create(String table, callback) {}

  void drop(String table) {}

  void dropIfExists(String table) {}

}
