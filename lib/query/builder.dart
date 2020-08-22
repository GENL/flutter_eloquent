import 'package:sqflite_common/sqlite_api.dart' as sqliteApi;

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

  String _limit;

  Verb _verb;

  /// Keys of prepared statements
  List<String> _keys = [];
  /// Values of prepared create, update, delete statements
  List<String> _values = [];
  /// Values of prepared statements for a select
  List<String> whereClauseValues = [];

  sqliteApi.Database db;

  /// Tell whether [toRawSql] must return a sql raw for preaprered statement.
  bool _preparedStatements = true;

  /// All of the available clause operators.
  final _operators = [
    '=', '<', '>', '<=', '>=', '<>', '!=', /*'<=>'*/
    'like', /*'like binary'*/ 'not like', /*'ilike'*/ 'in',
    'is', 'is not'
    /*'&', '|', '^', '<<', '>>',
    'rlike', 'not rlike', 'regexp', 'not regexp',
    '~', '~*', '!~', '!~*', 'similar to',
    'not similar to', 'not ilike', '~~*', '!~~*'*/
  ];

  Builder(this.db);

  Builder table(String table) {
    _table = table;
    return this;
  }

  Builder select([List<String> fields = const []]) {
    _verb = Verb.select;
    _selects = fields;
    return this;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    _verb = Verb.create;
    _keys = data.keys.toList();
    _values = data.values.toList();

    int id = await db.rawInsert(toRawSql(), _values);
    return await select().where('id', id).first();
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
    return this.where('id', '=', id).first(columns);
  }

  /// Execute a query for the last record.
  Future<Map<String, dynamic>> last([List<String> columns = const [], String columnName]) {
    return select(columns).orderByDesc([columnName]).first();
  }

  /// Execute a raw SQL SELECT query
  ///
  /// Returns a list of rows that were found
  Future<List<Map<String, dynamic>>> _executeRaw() {
    return db.rawQuery(toRawSql(), whereClauseValues);
  }

  /// Add a basic where clause to the query.
  /// Do not use this to check nullability, instead use [whereNull] and [whereNotNull].
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

  Future<int> count([List<String> columns = const ['*']]) {
    // Clear the previous selected fields.
    return get(columns).then((value) {
      print('Count Data ===> $value');
      return value.length;
    });
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

  String toRawSql() {
    assert(_table != null);

    _keys = _keys.map((k) => '`$k`').toList();

    List<String> parts = [];
    switch (_verb) {
      case Verb.select:
        parts = _makeSelect();
        break;
      case Verb.create:
        parts = _makeCreate();
        break;
      case Verb.update:
        // TODO: Handle this case.
        break;
      case Verb.delete:
        // TODO: Handle this case.
        break;
    }
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
      parts.add(_selects.join(', '));
    } else {
      parts.add('*');
    }
    if (this._orderBys.isNotEmpty) {
      parts.add("ORDER BY");
      parts.add(_orderBys.join(', '));
    }
    if (this._limit != null) {
      parts.add("LIMIT");
      parts.add(this._limit);
    }

    parts.addAll(['FROM', _table]);

    if (_wheres.isNotEmpty) {
      String completeCondition = '';
      // bool whereBooleansContainOr = _whereBooleans.contains('OR');
      bool whereBooleansContainOr = _wheres.firstWhere(
          (clause) => clause.boolean == 'OR', orElse: () => null) != null;
      _wheres.asMap().forEach((index, condition) {
        // Fill the where clause value. These values will we used for prepared
        // statements.
        whereClauseValues.add(condition.value);
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

  List<String> _makeCreate() {
    List<String> parts = [];
    parts.add("INSERT INTO");
    parts.add(_table);
    parts.add("(${_keys.join(', ')})");
    parts.add("VALUES");
    // parts.add("('${_values.join('\', \'')}')"); // _values.join('', '')
    // Use the question mark syntax for prepared statement.
    parts.add('(' +
      List<String>.generate(_values.length, (index) => '?').join(', ') +
      ')');
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

/// Sometimes where conditions contains spaces.
/// We wrap non-numeral values into single-quotes.
String _parseConditionValue(dynamic value) {
  if (value == null) return 'NULL';
  if (value is bool) return value ? '1' : '0';
  return num.tryParse(value.toString())?.toString() ?? "'$value'";
}

enum Verb {
  select, create, update, delete
}


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
