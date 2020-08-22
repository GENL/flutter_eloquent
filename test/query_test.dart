import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart' as t;
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_eloquent/flutter_eloquent.dart';

void initDb() {

}

Builder get query => new Builder();

void main() {
  test('Test "where" grammar verb', () {
    final q = query.table('posts').select(['name']);

    t.expect(q.toRawSql(), "SELECT name FROM posts");
  });

  test("Test 'where' grammar verb", () {
    Builder q = query
      .table('posts')
      .where('id', '=', 1);
    // t.expect(q.toRawSql(), "SELECT * FROM posts WHERE id = 1");

    // test empty operator and "AND" boolean.
    q = query
      .table('posts')
      .where('id', 1)
      .where('name', 'Post 1');
    // t.expect(q.toRawSql(), "SELECT * FROM posts WHERE id = 1 AND name = 'Post 1'");

    final now = DateTime.now().toIso8601String();
    // Test or where
    q = query
      .table('posts')
      .where('id', '>', 1)
      .orWhere('name', 'Post 1')
      .orWhere('created_at', now)
      .where('deleted_at', '!=', null)
      .where('is_active', true)
      .orWhere('is_admin', true);
    print('Raw ====> ${q.toRawSql()}');
    t.expect(q.toRawSql(), "SELECT * FROM posts"
      " WHERE (id > 1 OR name = 'Post 1' OR created_at = '$now')"
      " AND (deleted_at is not NULL)"
      " AND (is_active = 1 OR is_admin = 1)"
    );
  });
}
