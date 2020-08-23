import 'package:flutter/cupertino.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqliteApi;

// todo: inner join, pagination, factories, seeders

class Builder {
  List<String> _selects = [];

  String _table;

  List<WhereClause> _wheres = [];

  /// This represents the boolean of the where clause.
  /// So [_whereBooleans.elementAt(0)] is the boolean of
  /// _where.elementAt(0).
  ///
  /// A where boolean is "AND" or "OR".
  // List<String> _whereBooleans = [];

  List<String> _group = [];

  List<String> _orderBys = [];

  /// The flag for counting the query record.
  bool _count = false;

  String _limit;

  Verb _verb;

  /// Keys of prepared statements
  List<String> _keys = [];
  /// Values of prepared create, update, delete statements
  List<String> _values = [];
  /// Allows to save [_values] when [_preparedStatements] is false
  List<String> _savedValues = [];

  /// Values of prepared statements for a select
  List<String> _whereClauseValues = [];
  /// Allows to save [_savedWhereClauseValues] when [_preparedStatements] is false
  List<String> _savedWhereClauseValues = [];

  sqliteApi.Database db;

  /// Tell whether [toRawSql] must return a sql raw for preaprered statement.
  bool _preparedStatements = true;

  /// All of the available clause operators.
  final _operators = [
    '=', '<', '>', '<=', '>=', '<>', '!=', /*'<=>'*/
    'like', /*'like binary'*/ 'not like', 'rlike', 'not rlike', /*'ilike'*/
    'in', 'is', 'is not'
    /*'&', '|', '^', '<<', '>>',
    'rlike', 'not rlike', 'regexp', 'not regexp',
    '~', '~*', '!~', '!~*', 'similar to',
    'not similar to', 'not ilike', '~~*', '!~~*'*/
  ];

  /// Create a new query builder instance.
  ///
  // Every columns passed to [insert], [update], [delete], [count], [get],
  // [first], [find] methods override those from [select] method
  Builder(this.db);

  Builder table(String table) {
    _table = table;
    return this;
  }

  /// Add a select statement to the query.
  ///
  /// If at a moment the fields are empty which signifies select all ['*'],
  /// we override all other selects. So the final statement will become
  /// SELECT * FROM ...
  /// or SELECT COUNT(*) FROM ...
  Builder select([List<String> fields = const []]) {
    _verb = Verb.select;

    if (fields.isEmpty) {
      _selects.clear();
    } else {
      _selects.addAll(fields);
    }
    // Remove duplicate columns from the list.
    _selects = new Set<String>.from(_selects).toList();
    return this;
  }

  /// Insert a new record into the database.
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    _verb = Verb.create;
    _keys = data.keys.toList();
    _values = data.values.map((v) => _parseConditionValue(v)).toList();

    int id = await db.rawInsert(toRawSql(), _values);
    return await select().where('id', id).first();
  }

  /// Update a record in the database.
  ///
  /// return the number of updated records.
  Future<int> update(Map<String, dynamic> data) async {
    _verb = Verb.update;
    _keys = data.keys.toList();
    _values = data.values.map((v) => _parseConditionValue(v)).toList();
    return await db.rawUpdate(toRawSql(), _values);
  }

  /// Delete a record in the database.
  ///
  /// return the number of deleted records.
  Future<int> delete() async {
    _verb = Verb.delete;
    return await db.rawDelete(toRawSql());
  }

  /// Execute the query as a "select" statement.
  Future<List<Map<String, dynamic>>> get([List<String> columns = const []]) {
    return select(columns)._executeRaw();
  }

  /// Execute a query for the first record.
  Future<Map<String, dynamic>> first([List<String> columns = const []]) async {
    return (await select(columns).take(1)._executeRaw()).first;
  }

  /// Execute a query for a single record by ID.
  Future<Map<String, dynamic>> find(int id, [List<String> columns = const []]) {
    return where('id', '=', id).first(columns);
  }

  /// Execute a query for the last record.
  Future<Map<String, dynamic>> last([List<String> columns = const [], String columnName]) {
    return select(columns).orderByDesc([columnName]).first();
  }

  /// Execute a raw SQL SELECT query
  ///
  /// Returns a list of rows that were found
  Future<List<Map<String, dynamic>>> _executeRaw() {
    return db.rawQuery(toRawSql(), _whereClauseValues);
  }

  /// Add a basic where clause to the query.
  Builder where(String column, dynamic operator, [dynamic value, String boolean = 'AND']) {
    assert(value is String || value is num || value == null || value is bool);

    // Here we will make some assumptions about the operator. If only 2 values are
    // passed to the method, we will assume that the operator is an equals sign
    // and keep going. Otherwise, we'll require the operator to be passed in.
    assert(
        (value != null || _operators.contains(operator)) ||
            (value == null && !_operators.contains(operator)),
        'Ambiguous operator-value pair. If the value is null the only '
        'valid values for the operator are: $_operators');

    boolean = boolean.toUpperCase();
    assert(boolean == 'AND' || boolean == 'OR');

    // The first WHERE is always considered as an "AND" condition.
    if (_wheres.isEmpty) boolean = 'AND';
    if (operator == '<>') operator = '!=';

    if (value == null && !_operators.contains(operator)) {
      value = operator;
      operator = '=';
    }

    // If the value is "null", we will just assume the developer wants to add a
    // where null clause to the query. So, we will allow a short-cut here to
    // that method for convenience so the developer doesn't have to check.
    if (value == null) {
      return whereNull(column, boolean, operator != '=');
    }

    /*if (value == null) {
      //if (operator != '=' && operator != '!=') operator = '=';
      // When the operator is not defined, we assume that it is equal.
      if (operator == '=') {
        operator = 'is';
      } else if (operator == '!=') {
        operator = 'is not';
      }
    }*/

    // _wheres.add("$column $operator ${_parseConditionValue(value)}");
    // _whereBooleans.add(boolean);
    _wheres.add(new WhereClause(
      column: column,
      operator: operator,
      value: value,
      boolean: boolean
    ));

    // Multi columns
    // [column].forEach((column_) {
        // _where.add("$column_$operator'$value'");
    // });

    return this;
  }

  Builder orWhere(String column, dynamic operator, [dynamic value]) {
    return where(column, operator, value, 'OR');
  }

  /// Add a "where null" clause to the query.
  Builder whereNull(String column, [String boolean = 'AND', bool notNull = false]) {
    boolean = boolean.toUpperCase();
    assert(boolean == 'AND' || boolean == 'OR');

    // _wheres.add("$column is${notNull ? ' not' : ''} NULL");
    _wheres.add(new WhereClause(
      column: column,
      operator: notNull ? 'is not' : 'is',
      value: null,
      boolean: boolean
    ));
    // _whereBooleans.add(boolean);
    return this;
  }

  /// Add a "where not null" clause to the query.
  Builder whereNotNull(String column, [String boolean = 'AND']) {
    return whereNull(column, boolean, true);
  }

  /// Add an "or where null" clause to the query.
  Builder orWhereNull(String column) {
    return whereNull(column, 'OR');
  }

  /// Add an "or where not null" clause to the query.
  Builder orWhereNotNull(String column) {
    return whereNull(column, 'OR', true);
  }

  // Add a basic 'where like' clause to the query
  //
  /// Finds any values that have "or" in any position
//  Builder whereLike(String column, String value) {
//    return where(column, 'like', '%$value%');
//  }

  /// Count the result of a query.
  Future<int> count([String column = '*']) async {
    assert(column != null);
    _count = true;
    // Remove the select that already exist to prevent the aql COUNT function to have
    // multiple parameter.
    _selects.clear();
    List<Map<String, dynamic>> result =
      (await select(column == '*' ? [] : [column])._executeRaw());
    return result.first.values.first;
  }

  /// Set the "limit" value of the query.
  Builder limit(int limit) {
    if (limit > 0) this._limit = limit.toString();
    return this;
  }

  /// Alias to set the "limit" value of the query.
  Builder take(int value) {
    return limit(value);
  }

  /// Add an "order by" clause to the query.
  Builder orderBy(List<String> columns, [String direction = 'asc']) {
    assert(direction.toLowerCase() == 'asc' || direction.toLowerCase() == 'desc');
    this._orderBys.add("${columns.join(', ')} ${direction.toUpperCase()}");
    return this;
  }

  /// Add an "order by desc" clause to the query.
  Builder orderByDesc(List<String> columns) {
    return orderBy(columns, 'desc');
  }

  /// Returns the raw sql.
  ///
  /// If [forExecution] is true, so we apply the modification
  /// to prepare the sql string to be executed by sqlite.
  /// These modification includes for example prepared statements.
  ///
  /// if [forExecution] is false, statements are not prepared at all.
  String toRawSql(/*{bool forExecution = true}*/) {
    assert(_table != null);

    _keys = _keys.map((k) => '`$k`').toList();
    _savedValues = List.from(_values);
    _savedWhereClauseValues = List.from(_whereClauseValues);

    // bool preparedStatements = _preparedStatements;
    // if (forExecution) _preparedStatements = false;

    List<String> parts = [];
    switch (_verb) {
      case Verb.select:
        parts = _makeSelect();
        break;
      case Verb.create:
        parts = _makeCreate();
        break;
      case Verb.update:
        parts = _makeUpdate();
        break;
      case Verb.delete:
        parts = _makeDelete();
        break;
      default:
        throw "You try to get the raw of an incomplete statement."
          " None of the verbs was defined (SELECT, UPDATE, DELETE, INSERT)";
    }

    // When the developer does not want to prepare the request, the
    // values are cleared. This affect the whole Builder instance
    // so when the developer wants prepared statements again, the values
    // we re-filled if they were not been modified.
    if (!_preparedStatements) {
      _values.clear();
      _whereClauseValues.clear();
    } else {
      if (_values.isEmpty) _values = _savedValues;
      if (_whereClauseValues.isEmpty) _savedWhereClauseValues = _whereClauseValues;
    }

    // _preparedStatements = preparedStatements;

    return parts.join(' ');
  }

  void _resetBuilder() {
    _selects = [];
    _table = null;
    _wheres = [];
    _orderBys = [];
    _limit = null;
    _keys = [];
    _values = [];
    _verb = null;
    withPreparedStatements();
  }

  List<String> _makeSelect() {
    List<String> parts = ['SELECT'];
    if (_selects.isNotEmpty) {
      var select = _selects.join(', ');
      if (_count)
        parts.add('COUNT($select)');
      else
        parts.add(select);
    } else {
      if (_count)
        parts.add('COUNT(*)');
      else
        parts.add('*');
    }

    parts.addAll(['FROM', _table]);

    parts.addAll(_getWheresParts());

    if (this._orderBys.isNotEmpty) {
      parts.add("ORDER BY");
      parts.add(_orderBys.join(', '));
    }
    if (this._limit != null) {
      parts.add("LIMIT");
      parts.add(this._limit);
    }

    return parts;
  }

  List<String> _makeCreate() {
    List<String> parts = [];
    parts.add("INSERT INTO");
    parts.add(_table);
    parts.add("(${_keys.join(', ')})");
    parts.add("VALUES");
    // Use the question mark syntax for prepared statement.
    if (_preparedStatements) {
      parts.add('(' +
        List<String>.generate(_values.length, (index) => '?').join(', ') +
        ')');
    } else {
      parts.add("(" +
        _values.join(", ") +
        ")");
    }
    return parts;
  }

  List<String> _makeUpdate() {
    List<String> parts = [];
    parts.addAll(["UPDATE", _table, "SET"]);
    Iterable data = _keys
      .asMap()
      .map((index, key) => MapEntry(index, "$key=${_preparedStatements ? '?' : _values[index]}"))
      .values;
    parts.add(data.join(", "));
    if (_wheres.isEmpty) {
      print('[flutter_eloquent] Update Statement Warning!!'
        ' Be careful when updating records. If you omit the WHERE clause, ALL records will be updated!');
    }
    parts.addAll(_getWheresParts());
    return parts;
  }

  List<String> _makeDelete() {
    List<String> parts = [];
    parts.addAll(['DELETE', 'FROM', _table]);
    if (_wheres.isEmpty) {
      print("[flutter_eloquent] Delete Statement Warning!!"
        " Be careful when deleting records in a table!"
        " Notice the WHERE clause in the DELETE statement."
        " The WHERE clause specifies which record(s) should be deleted."
        " If you omit the WHERE clause, all records in the table will be deleted!");
    }
    parts.addAll(_getWheresParts());
//    if (this._limit != null) {
//      parts.addAll(["LIMIT", _limit]);
//    }
    return parts;
  }

  /// Returns where parts that should be added to the raw query.
  List<String> _getWheresParts() {
    List<String> parts = [];
    if (_wheres.isNotEmpty) {
      String completeCondition = '';
      // bool whereBooleansContainOr = _whereBooleans.contains('OR');
      bool whereBooleansContainOr = _wheres.firstWhere(
          (clause) => clause.boolean == 'OR', orElse: () => null) != null;
      _wheres.asMap().forEach((index, condition) {
        // Fill the where clause value. These values will we used for prepared
        // statements.
        _whereClauseValues.add(condition.value);
        int lastIndex = _wheres.length - 1;
        /*String boolean = _whereBooleans[index];
        String nextBoolean = index + 1 <= lastIndex ? _whereBooleans[index + 1] : null;*/
        String boolean = condition.boolean;
        String nextBoolean = index + 1 <= lastIndex ? _wheres[index + 1].boolean : null;

        if (boolean == 'AND') {
          if (whereBooleansContainOr) completeCondition += '(';
        } else /*if (boolean == 'OR')*/ {
          completeCondition += ' OR ';
        }

        completeCondition += condition.toString(preparedStatement: _preparedStatements);

        if (nextBoolean == 'AND' || index == lastIndex) {
          if (whereBooleansContainOr) completeCondition += ')';
          if (index < _wheres.length - 1) {
            completeCondition += ' AND ';
          }
        }
      });
      parts.addAll(['WHERE', completeCondition]);
    }
    return parts;
  }

  /// Tells the raw sql must use prepared statements.
  Builder withPreparedStatements() {
    _preparedStatements = true;
    return this;
  }

  /// Tells the raw sql must not use prepared statements.
  Builder withoutPreparedStatements() {
    _preparedStatements = false;
    return this;
  }

}

/// Parse [value] for it to be in the good form for the sql raw
///
/// If [value] is boolean, replaces by 0 (false) or 1 (true).
///
/// If [value] is null, returns NULL
///
/// If [value] is String, returns the same string in the single-quotes.
String _parseConditionValue(dynamic value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? '1' : '0';
  return num.tryParse(value.toString())?.toString() ?? "'$value'";
}

enum Verb {
  select, create, update, delete
}

/// Represents a where clause.
class WhereClause {
  String column;
  String operator;
  String _value;
  String _boolean;

  /// Represents a where clause.
  WhereClause({dynamic value, this.column, this.operator, String boolean})
      : assert(
            boolean.toUpperCase() == 'AND' || boolean.toUpperCase() == 'OR') {
    this.value = value;
    this.boolean = boolean;
  }

  String get value => _value;
  set value(dynamic value) => _value = _parseConditionValue(value);

  String get boolean => _boolean;
  set boolean(String value) {
    assert(value.toUpperCase() == 'AND' || value.toUpperCase() == 'OR');
    _boolean = value.toUpperCase();
  }

  /// Represents the format in which the where clause is
  /// inserted into the raw sql.
  @override
  String toString({bool preparedStatement = true}) {
    String value = preparedStatement ? '?' : this.value;
    return "$column $operator $value";
  }
}
